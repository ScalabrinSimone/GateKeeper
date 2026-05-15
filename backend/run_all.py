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


def _print_pairing_qr(host: str, port: int) -> None:
    """Stampa nel terminale il QR-code di pairing.

    Il contenuto è un JSON compatto, lo stesso che l'app può ottenere via
    `GET /hub/qr`. La libreria `qrcode` è opzionale: se non è installata
    stampiamo comunque i dati in chiaro così l'utente può inserirli a mano.
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
    log("INFO", f"URL hub:        {payload['baseUrl']}")
    log("INFO", f"Factory code:   {code}")
    log("INFO", "Inquadra il QR dall'app GateKeeper per configurare l'hub.")
    log("INFO", "Oppure inserisci URL e codice manualmente in app.")

    try:
        import qrcode  # type: ignore
        qr = qrcode.QRCode(border=1)
        qr.add_data(text)
        qr.make(fit=True)
        # `print_ascii` stampa il QR usando caratteri unicode "▀" / "▄".
        # invert=True rende il QR leggibile su terminali a sfondo scuro.
        qr.print_ascii(invert=True)
    except ModuleNotFoundError:
        log(
            "WARN",
            "Pacchetto 'qrcode' non installato: pip install qrcode "
            "per stampare il QR ASCII.",
        )
        print()
        print(text)
        print()


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

    args = parser.parse_args()

    # Esponiamo la porta API come variabile d'ambiente per altri thread
    # (es. discovery listener che la include nella sua risposta).
    import os
    os.environ["GK_API_PORT"] = str(args.port)

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
        log("INFO", "Backend terminato")


# =========================================================
# ENTRY POINT
# =========================================================


if __name__ == "__main__":
    main()