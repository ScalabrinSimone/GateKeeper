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
# PARSER TAG RFID
# =========================================================


def parseTag(line: str) -> Optional[str]:
    """Estrae EPC dalla risposta RFID."""

    line = line.strip()

    if line.startswith("U") and len(line) > 5:
        return line[1:].strip()

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
    """Avvia il lettore RFID."""

    global PORT

    PORT = get_port()

    if stop_event is None:
        stop_event = threading.Event()

    printSection("LETTORE RFID UHF")

    log("INFO", f"Porta seriale: {PORT}")
    log("INFO", f"Baudrate: {BAUD}")
    log("INFO", f"RF_POWER: {RF_POWER}")
    log("INFO", f"SCAN_INTERVAL: {SCAN_INTERVAL}")
    log("INFO", f"SERIAL_TIMEOUT: {SERIAL_TIMEOUT}")
    log("INFO", f"SHOW_ONLY_UNIQUE_TAGS: {SHOW_ONLY_UNIQUE_TAGS}")
    log("INFO", f"UNIQUE_TAG_RESET_SECONDS: {UNIQUE_TAG_RESET_SECONDS}")

    try:
        with serial.Serial(PORT, BAUD, timeout=SERIAL_TIMEOUT) as ser:
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

    except serial.SerialException as exc:
        log("ERROR", f"Errore seriale RFID: {exc}")

    except KeyboardInterrupt:
        log("WARN", "Stop manuale lettore RFID")

    finally:
        try:
            if "ser" in locals():
                ser.write(b"\nu\r")
                ser.flush()

        except Exception:
            pass

        log("INFO", "Lettore RFID fermato")


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