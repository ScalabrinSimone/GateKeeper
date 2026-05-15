#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Lettore RFID UHF seriale con output terminale pulito ed elegante.

FEATURES:
- Lettura RFID continua
- Polling ultra veloce configurabile
- Potenza RFID configurabile
- Timeout seriale configurabile
- Modalità "solo tag unici"
- Callback custom on_tag(tag)
- Compatibile standalone/thread/API
"""

from __future__ import annotations

import argparse
import os
import re
import threading
import time
from typing import Callable, Optional

import serial

# =========================================================
# IMPORT PORTFINDER
# =========================================================

try:
    from app.rfid.portfinder import get_port
except ModuleNotFoundError:
    from portfinder import get_port

# =========================================================
# CONFIGURAZIONE GLOBALE
# =========================================================

PORT = None

# Baudrate lettore RFID
BAUD = 38400

# ---------------------------------------------------------
# POTENZA RFID
# ---------------------------------------------------------

RF_POWER = "1B"

# ---------------------------------------------------------
# VELOCITÀ SCANSIONE
# ---------------------------------------------------------

SCAN_INTERVAL = 0.05

# ---------------------------------------------------------
# TIMEOUT SERIALE
# ---------------------------------------------------------

SERIAL_TIMEOUT = 0.05

# ---------------------------------------------------------
# MOSTRA SOLO TAG UNICI
# ---------------------------------------------------------

SHOW_ONLY_UNIQUE_TAGS = False

# ---------------------------------------------------------
# RESET TAG UNICI
# ---------------------------------------------------------

UNIQUE_TAG_RESET_SECONDS = 3.0

# =========================================================
# CACHE TAG
# =========================================================

seenTags: dict[str, float] = {}

# =========================================================
# UTILS LOGGING
# =========================================================


def getTimestamp() -> str:
    return time.strftime("%H:%M:%S")


def log(level: str, message: str) -> None:
    print(f"[{getTimestamp()}] [RFID] {level:<7} {message}")


def printSection(title: str) -> None:
    line = "─" * max(8, len(title) + 2)

    print()
    print(f"┌{line}┐")
    print(f"│ {title} │")
    print(f"└{line}┘")


# =========================================================
# FUNZIONI SERIALI
# =========================================================


def sendCommand(
    ser: serial.Serial,
    cmd: str,
    wait: float = 0.10
) -> str:
    """Invia comando al lettore RFID."""

    payload = b"\n" + cmd.encode("ascii") + b"\r"

    log("TX", cmd)

    ser.write(payload)
    ser.flush()

    time.sleep(wait)

    bytesWaiting = ser.in_waiting
    data = ser.read(bytesWaiting if bytesWaiting else 1)

    try:
        text = data.decode("ascii", errors="ignore")
    except Exception:
        text = str(data)

    if text:
        log("RX", repr(text))

    return text


# =========================================================
# PARSER TAG RFID (tollerante a più firmware)
# =========================================================

# Espressione che cattura blocchi esadecimali "lunghi" (>=12 hex char) che
# tipicamente rappresentano l'EPC (24 char per tag UHF EPC Gen2 da 96 bit).
# Esempi di linee accettate:
#   "U30001234ABCD..."
#   "EPC: 3000 1234 ABCD ..."
#   "3000 1234 ABCD 5678 9ABC DEF0"
#   "\x02U30001234...\x03"
_HEX_TOKEN_RE = re.compile(r"[0-9A-Fa-f]{12,}")

# Righe-echo o di handshake comuni che vogliamo ignorare.
_IGNORE_PREFIXES = ("V", "S", "N", "W", "u", ">", "<", "OK", "ERR")

# Quando GK_RFID_DEBUG=1 stampiamo tutto il raw seriale: utile per capire
# il protocollo di un firmware nuovo senza dover modificare il codice.
_DEBUG_MODE = os.environ.get("GK_RFID_DEBUG", "").strip() in ("1", "true", "True", "yes")


def _normalize_hex(text: str) -> str:
    """Rimuove spazi/separatori comuni dentro un token esadecimale."""
    return re.sub(r"[\s\-:]", "", text).upper()


def parseTag(line: str) -> Optional[str]:
    """Estrae l'EPC dalla risposta seriale.

    Strategia (in ordine):
    1. il classico formato Chafon: la riga inizia con 'U' seguita dall'EPC,
    2. estrazione di un token hex lungo (≥12 char) ovunque nella riga,
    3. ignora righe vuote, echo dei comandi (V/S/N/W/u/...) e prompt.

    Restituisce l'EPC in maiuscolo, senza separatori, oppure None.
    """
    if not line:
        return None
    # Rimuovi byte STX/ETX e altri caratteri di controllo non stampabili.
    cleaned = "".join(ch for ch in line if ch.isprintable() or ch in (" ", "\t"))
    cleaned = cleaned.strip()
    if not cleaned:
        return None

    if _DEBUG_MODE:
        log("DBG", f"line={cleaned!r}")

    # 1) Formato classico: U<hex>
    if cleaned.startswith("U") and len(cleaned) > 5:
        candidate = _normalize_hex(cleaned[1:])
        if re.fullmatch(r"[0-9A-F]{12,}", candidate):
            return candidate

    # 2) Echo/handshake → ignora.
    for prefix in _IGNORE_PREFIXES:
        if cleaned.startswith(prefix) and not _HEX_TOKEN_RE.search(cleaned):
            return None

    # 3) Token esadecimale più lungo presente nella riga.
    matches = _HEX_TOKEN_RE.findall(cleaned)
    if matches:
        # Prendiamo il match più lungo per evitare di catturare codici brevi.
        best = max(matches, key=len)
        return _normalize_hex(best)

    return None


# =========================================================
# FILTRO TAG UNICI
# =========================================================


def shouldShowTag(tag: str) -> bool:
    """Decide se mostrare il tag."""

    if not SHOW_ONLY_UNIQUE_TAGS:
        return True

    now = time.time()

    expiredTags = []

    for epc, timestamp in seenTags.items():
        if now - timestamp > UNIQUE_TAG_RESET_SECONDS:
            expiredTags.append(epc)

    for epc in expiredTags:
        del seenTags[epc]

    if tag in seenTags:
        return False

    seenTags[tag] = now

    return True


# =========================================================
# CONFIGURAZIONE LETTORE
# =========================================================


def configureReader(
    ser: serial.Serial
) -> None:
    """Configura il lettore RFID."""

    printSection("CONFIGURAZIONE RFID")

    sendCommand(ser, "u")

    log("INFO", f"Potenza RFID impostata a {RF_POWER}")

    sendCommand(ser, f"N1,{RF_POWER}")

    log("INFO", "Verifica potenza corrente")

    sendCommand(ser, "N0,00")

    sendCommand(ser, "W")

    log("OK", "Configurazione completata")


# =========================================================
# LOOP PRINCIPALE RFID
# =========================================================


def runReader(
    stop_event: Optional[threading.Event] = None,
    on_tag: Optional[Callable[[str], None]] = None,
) -> None:
    """Avvia il lettore RFID con retry automatico.

    - Se la porta seriale non è disponibile (chiavetta non collegata),
      il thread NON crasha: rimane in attesa e fa retry ogni qualche
      secondo finché il dispositivo non viene rilevato.
    - In caso di disconnessione runtime (cavo staccato, errore I/O),
      il loop esterno riapre la porta al volo.
    - `stop_event.set()` interrompe sia il retry che il loop di lettura.
    """

    global PORT

    if stop_event is None:
        stop_event = threading.Event()

    printSection("LETTORE RFID UHF")
    log("INFO", f"Baudrate: {BAUD}")
    log("INFO", f"RF_POWER: {RF_POWER}")
    log("INFO", f"SCAN_INTERVAL: {SCAN_INTERVAL}")
    log("INFO", f"SERIAL_TIMEOUT: {SERIAL_TIMEOUT}")
    log("INFO", f"SHOW_ONLY_UNIQUE_TAGS: {SHOW_ONLY_UNIQUE_TAGS}")
    log("INFO", f"UNIQUE_TAG_RESET_SECONDS: {UNIQUE_TAG_RESET_SECONDS}")

    # Loop esterno: retry continuo finché il sensore non è raggiungibile.
    retry_delay = 3.0
    while not stop_event.is_set():
        PORT = get_port()
        if not PORT:
            log(
                "WARN",
                "Nessuna porta seriale per il lettore RFID. "
                f"Riprovo tra {retry_delay:.0f}s.",
            )
            # Sleep "interrompibile" basato sull'evento.
            if stop_event.wait(retry_delay):
                break
            continue

        log("INFO", f"Porta seriale: {PORT}")
        try:
            _readerInnerLoop(PORT, stop_event=stop_event, on_tag=on_tag)
        except serial.SerialException as exc:
            log("ERROR", f"Errore seriale: {exc}. Riprovo tra {retry_delay:.0f}s.")
        except OSError as exc:
            # Es. errno 2 "No such file or directory" se la chiavetta viene staccata.
            log("ERROR", f"Errore I/O: {exc}. Riprovo tra {retry_delay:.0f}s.")
        except Exception as exc:
            log("ERROR", f"Errore inatteso lettore RFID: {exc}")

        if stop_event.is_set():
            break
        # Aspetta prima di riprovare ad aprire la porta.
        if stop_event.wait(retry_delay):
            break

    log("INFO", "Lettore RFID fermato")


def _readerInnerLoop(
    port: str,
    *,
    stop_event: threading.Event,
    on_tag: Optional[Callable[[str], None]],
) -> None:
    """Loop interno: apre la porta seriale e legge i tag finché non c'è errore."""
    try:
        with serial.Serial(port, BAUD, timeout=SERIAL_TIMEOUT) as ser:
            ser.reset_input_buffer()
            ser.reset_output_buffer()

            printSection("TEST COMUNICAZIONE")

            sendCommand(ser, "V")
            sendCommand(ser, "S")

            configureReader(ser)

            printSection("SCANSIONE RFID ATTIVA")

            log("OK", "Avvicina un tag RFID UHF")

            buffer = ""
            lastInventory = 0.0

            while not stop_event.is_set():
                now = time.time()

                if now - lastInventory >= SCAN_INTERVAL:
                    ser.write(b"\nU\r")
                    ser.flush()

                    lastInventory = now

                data = ser.read(1024).decode(
                    "ascii",
                    errors="ignore"
                )

                if data:
                    buffer += data
                    if _DEBUG_MODE:
                        log("DBG", f"raw={data!r}")

                while "\n" in buffer or "\r" in buffer:
                    if "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                    else:
                        line, buffer = buffer.split("\r", 1)

                    tag = parseTag(line)

                    if not tag:
                        continue

                    if not shouldShowTag(tag):
                        continue

                    printSection("TAG RFID TROVATO")

                    log("OK", f"EPC: {tag}")

                    if on_tag is not None:
                        try:
                            on_tag(tag)

                        except Exception as exc:
                            log(
                                "ERROR",
                                f"Errore callback RFID: {exc}"
                            )

    except KeyboardInterrupt:
        log("WARN", "Stop manuale lettore RFID")
        # Propaghiamo lo stop fuori dal loop di retry.
        stop_event.set()


# =========================================================
# AVVIO STANDALONE
# =========================================================


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Lettore RFID UHF seriale"
    )

    parser.parse_args()

    runReader()


if __name__ == "__main__":
    main()