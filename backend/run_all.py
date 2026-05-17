"""Avvio unico del progetto.

Questo script:
1) inizializza il database NoSQL locale;
2) avvia il server FastAPI/Uvicorn (che a sua volta gestisce gli hook
   startup/shutdown per supervisor RFID + BLE);
3) se l'hub non è ancora accoppiato, stampa in console un QR-code con i
   dati di pairing (URL LAN + factory code) — pensato come "schermo" di un
   prodotto consumer pronto all'uso.

Il supervisor in `endpoint.py` attiva/disattiva i sensori RFID e BLE in
base allo stato di pairing dell'hub.
"""

from __future__ import annotations

import argparse
import json
import socket
import threading
import time

import uvicorn

from app.db import models as gk_models
from app.db.init_db import init_db

# =========================================================
# LOGGING
# =========================================================


def getTimestamp() -> str:
    return time.strftime("%H:%M:%S")


def log(level: str, message: str) -> None:
    print(f"[{getTimestamp()}] [BOOT] {level:<7} {message}")


def printSection(title: str) -> None:
    line = "─" * max(8, len(title) + 2)

    print()
    print(f"┌{line}┐")
    print(f"│ {title} │")
    print(f"└{line}┘")


# =========================================================
# PAIRING QR
# =========================================================


def _detect_lan_ip() -> str:
    """Restituisce l'IP LAN principale del Raspberry/PC.

    Trucco classico: apriamo un socket UDP "fittizio" verso un indirizzo
    pubblico (8.8.8.8); il kernel ci dice l'IP locale scelto per uscire.
    Non viene inviato nulla, ma è il metodo più affidabile cross-platform
    per scoprire l'IP esposto in LAN.
    """
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
        finally:
            s.close()
    except Exception:
        return "127.0.0.1"


def _ensure_factory_code() -> str:
    """Garantisce che esista un factory_code da mostrare nel QR.

    Se l'hub è già pairato, non lo tocca. Se invece il factory_code non
    esiste ancora (primo avvio), ne genera uno con `factory_reset_all`
    senza svuotare il database (alle prime esecuzioni il DB è già vuoto).
    """
    hub = gk_models.get_hub() or {}
    if hub.get("paired"):
        return ""  # già pairato, niente QR
    code = hub.get("factory_code")
    if code:
        return str(code)
    # Genera un nuovo codice senza distruggere dati esistenti.
    from secrets import token_hex
    new_code = token_hex(3).upper()
    gk_models.set_hub({"factory_code": new_code})
    return new_code


def _qrLog(level: str, message: str) -> None:
    """Helper: log specifico per il componente QR (prefisso [QR] per
    il routing su file separato quando si usa --split-logs)."""
    print(f"[{getTimestamp()}] [QR]   {level:<7} {message}")


def _print_pairing_qr(host: str, port: int) -> None:
    """Mostra il QR-code di pairing.

    Lo stesso payload viene servito anche da `GET /hub/qr`. La libreria
    `qrcode` è ora una dipendenza obbligatoria, ma manteniamo i fallback
    perché il QR vada in tre modi:
    1) ASCII direttamente nel terminale (più rapido),
    2) PNG su disco (`backend/logs/pairing_qr.png`) per quando si lavora
       senza terminale o senza supporto a caratteri unicode (es. seriale
       di un Raspberry headless),
    3) JSON testuale + URL e factory_code chiari da incollare in app.

    Le tre modalità non si escludono: l'utente può sempre inserire URL +
    factory_code a mano se il QR non funziona.
    """
    code = _ensure_factory_code()
    if not code:
        return  # hub già pairato

    hub = gk_models.get_hub() or {}
    payload = {
        "v": 1,
        "kind": "gatekeeper_pair",
        "baseUrl": f"http://{host}:{port}",
        "factoryCode": code,
        "houseName": hub.get("house_name"),
    }
    text = json.dumps(payload, separators=(",", ":"))

    printSection("PAIRING QR (in attesa dell'app)")
    _qrLog("INFO", f"URL hub:      {payload['baseUrl']}")
    _qrLog("INFO", f"Factory code: {code}")
    _qrLog("INFO", "Apri l'app GateKeeper e scegli 'Scansiona QR' oppure")
    _qrLog("INFO", "inserisci URL e codice manualmente.")

    # 1) Stampa ASCII (richiede la libreria qrcode).
    qr = None
    try:
        import qrcode  # type: ignore

        qr = qrcode.QRCode(border=1)
        qr.add_data(text)
        qr.make(fit=True)
        try:
            qr.print_ascii(invert=True)
        except Exception as exc:
            _qrLog("WARN", f"print_ascii fallita: {exc}")
    except ModuleNotFoundError:
        _qrLog(
            "WARN",
            "Pacchetto 'qrcode' non installato: pip install qrcode[pil] "
            "per la stampa del QR.",
        )

    # 2) Fallback / extra: salva sempre il QR come PNG su disco quando
    #    qrcode (e PIL) sono disponibili. Comodo se il terminale del
    #    Raspberry è headless: l'utente può aprire il file via SCP/SSH.
    if qr is not None:
        try:
            from pathlib import Path as _Path

            png_path = _Path(__file__).resolve().parent / "logs" / "pairing_qr.png"
            png_path.parent.mkdir(parents=True, exist_ok=True)
            img = qr.make_image(fill_color="black", back_color="white")
            img.save(png_path)
            _qrLog("INFO", f"QR salvato anche come immagine: {png_path}")
        except Exception as exc:
            _qrLog("WARN", f"Impossibile salvare il PNG del QR: {exc}")

    # 3) Sempre: stampa il payload in chiaro (utile per debug / log).
    _qrLog("INFO", f"payload={text}")


# =========================================================
# MAIN
# =========================================================


def main() -> None:
    """Avvio completo backend."""

    parser = argparse.ArgumentParser(
        description="Avvio completo progetto"
    )

    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host server API"
    )

    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Porta server API"
    )

    parser.add_argument(
        "--reset-db",
        action="store_true",
        help="Reset database all'avvio"
    )

    parser.add_argument(
        "--factory-reset",
        action="store_true",
        help="Esegue un factory reset (svuota DB e rigenera factory_code)"
    )

    parser.add_argument(
        "--split-logs",
        action="store_true",
        help=(
            "Scrive i log su file separati per componente in backend/logs/. "
            "Apri terminali multipli con 'Get-Content -Wait' (PowerShell) o "
            "'tail -f' (Linux/macOS) per vedere i log live di RFID/BLE/QR/...",
        ),
    )

    parser.add_argument(
        "--rfid-debug",
        action="store_true",
        help="Logga il raw seriale del lettore RFID (verbose).",
    )

    args = parser.parse_args()

    # Esponiamo la porta API come variabile d'ambiente per altri thread
    # (es. discovery listener che la include nella sua risposta).
    import os
    os.environ["GK_API_PORT"] = str(args.port)
    if args.rfid_debug:
        os.environ["GK_RFID_DEBUG"] = "1"

    # Split logs: deve essere attivato PRIMA di qualsiasi altro print.
    if args.split_logs:
        from app.logging_utils import install_split_logs
        logs_dir = install_split_logs(force=True)
        log("INFO", f"Tail multi-terminale disponibile in: {logs_dir}")
        log("INFO", "Esempio (PowerShell):")
        log("INFO", f"  Get-Content -Wait '{logs_dir}\\rfid.log'")
        log("INFO", f"  Get-Content -Wait '{logs_dir}\\ble.log'")
        log("INFO", f"  Get-Content -Wait '{logs_dir}\\qr.log'")

    printSection("AVVIO PROGETTO")

    log(
        "INFO",
        f"Host API: {args.host}"
    )

    log(
        "INFO",
        f"Porta API: {args.port}"
    )

    log(
        "INFO",
        f"Reset DB: {args.reset_db}"
    )

    init_db(force=args.reset_db)

    log(
        "OK",
        "Database inizializzato"
    )

    if args.factory_reset:
        from app.security import tokens as gk_tokens

        gk_tokens.reset_secret()
        new_state = gk_models.factory_reset_all()
        log("INFO", f"Factory reset eseguito. Codice: {new_state.get('factory_code')}")

    # Mostriamo subito il QR di pairing (se l'hub non è ancora accoppiato).
    # Su un Raspberry "consumer" questo è ciò che apparirebbe sullo
    # schermetto del dispositivo all'avvio.
    lan_ip = _detect_lan_ip()
    _print_pairing_qr(lan_ip, args.port)

    # Thread che monitora il flag `paired` e ristampa il QR ogni volta che
    # l'hub torna non-pairato (es. dopo factory reset via app o DELETE /auth/me).
    _qr_monitor_stop = threading.Event()

    def _qr_monitor_loop() -> None:
        was_paired = bool((gk_models.get_hub() or {}).get("paired"))
        while not _qr_monitor_stop.is_set():
            if _qr_monitor_stop.wait(3.0):
                break
            try:
                is_paired = bool((gk_models.get_hub() or {}).get("paired"))
            except Exception:
                is_paired = was_paired
            if was_paired and not is_paired:
                # L'hub è appena tornato non-pairato: ristampa il QR.
                log("INFO", "Hub non più pairato: ristampa QR di pairing.")
                _print_pairing_qr(lan_ip, args.port)
            was_paired = is_paired

    qr_monitor_thread = threading.Thread(
        target=_qr_monitor_loop,
        daemon=True,
        name="qr-monitor-thread",
    )
    qr_monitor_thread.start()

    try:
        printSection("SERVER API")
        log("INFO", "Avvio server FastAPI/Uvicorn")
        log("INFO", f"LAN: http://{lan_ip}:{args.port}")
        uvicorn.run(
            "app.api.endpoint:app",
            host=args.host,
            port=args.port,
            reload=False,
        )
    finally:
        _qr_monitor_stop.set()
        log("INFO", "Backend terminato")


# =========================================================
# ENTRY POINT
# =========================================================


if __name__ == "__main__":
    main()