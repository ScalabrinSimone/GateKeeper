#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Lettore RFID UHF seriale.

FEATURES:
- Lettura RFID continua
- Polling ultra veloce configurabile
- Potenza RFID configurabile
- Timeout seriale configurabile
- Modalità "solo tag unici"
- Callback custom on_tag(tag)
- Compatibile standalone/thread/API

=========================================================
CONFIGURAZIONE RAPIDA
=========================================================

RF_POWER
    Potenza RFID:
        "00" -> minima
        "1B" -> MASSIMA

SCAN_INTERVAL
    Intervallo inventory in secondi.
    Più basso = scansione più aggressiva.

SERIAL_TIMEOUT
    Timeout seriale.

SHOW_ONLY_UNIQUE_TAGS
    True  -> stampa solo nuovi tag
    False -> stampa tutti i tag continuamente

UNIQUE_TAG_RESET_SECONDS
    Dopo quanti secondi un tag viene considerato "nuovo".
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
#
# Range:
#   "00" -> minimo
#   "1B" -> MASSIMO
#
# ---------------------------------------------------------

RF_POWER = "1B"

# ---------------------------------------------------------
# VELOCITÀ SCANSIONE
# ---------------------------------------------------------
#
# Più basso = scansione più veloce
#
# 0.02 = molto aggressivo
# 0.05 = stabile
# 0.10 = più leggero
#
# ---------------------------------------------------------

SCAN_INTERVAL = 0.02

# ---------------------------------------------------------
# TIMEOUT SERIALE
# ---------------------------------------------------------

SERIAL_TIMEOUT = 0.05

# ---------------------------------------------------------
# MOSTRA SOLO TAG UNICI
# ---------------------------------------------------------
#
# True:
#   mostra solo nuovi tag
#
# False:
#   mostra tutto continuamente
#
# ---------------------------------------------------------

SHOW_ONLY_UNIQUE_TAGS = False

# ---------------------------------------------------------
# RESET TAG UNICI
# ---------------------------------------------------------
#
# Dopo quanti secondi
# un tag viene considerato nuovo.
#
# ---------------------------------------------------------

UNIQUE_TAG_RESET_SECONDS = 3.0

# =========================================================
# CACHE TAG
# =========================================================

seen_tags: dict[str, float] = {}

# =========================================================
# FUNZIONI SERIALI
# =========================================================


def send_cmd(
    ser: serial.Serial,
    cmd: str,
    wait: float = 0.10
) -> str:
    """
    Invia comando al lettore RFID.
    """

    payload = b"\n" + cmd.encode("ascii") + b"\r"

    print(f"\nTX -> {cmd}")

    ser.write(payload)
    ser.flush()

    time.sleep(wait)

    n = ser.in_waiting

    data = ser.read(n if n else 1)

    try:
        text = data.decode(
            "ascii",
            errors="ignore"
        )
    except Exception:
        text = str(data)

    if text:
        print("RX ->", repr(text))

    return text


# =========================================================
# PARSER TAG RFID
# =========================================================


def parse_tag(line: str) -> Optional[str]:
    """
    Estrae EPC dalla risposta RFID.
    """

    line = line.strip()

    if line.startswith("U") and len(line) > 5:
        return line[1:].strip()

    return None


# =========================================================
# FILTRO TAG UNICI
# =========================================================


def should_show_tag(tag: str) -> bool:
    """
    Decide se mostrare il tag.
    """

    if not SHOW_ONLY_UNIQUE_TAGS:
        return True

    now = time.time()

    # Pulizia cache vecchia
    expired = []

    for epc, timestamp in seen_tags.items():
        if now - timestamp > UNIQUE_TAG_RESET_SECONDS:
            expired.append(epc)

    for epc in expired:
        del seen_tags[epc]

    # Tag già visto
    if tag in seen_tags:
        return False

    # Nuovo tag
    seen_tags[tag] = now

    return True


# =========================================================
# CONFIGURAZIONE LETTORE
# =========================================================


def configure_reader(
    ser: serial.Serial
) -> None:
    """
    Configura il lettore RFID.
    """

    print("\n===================================")
    print("CONFIGURAZIONE RFID")
    print("===================================")

    # Stop inventory
    send_cmd(ser, "u")

    # Potenza RFID
    print(f"\n>>> POTENZA RFID: {RF_POWER}")

    send_cmd(ser, f"N1,{RF_POWER}")

    # Verifica potenza
    print("\nVerifica potenza corrente:")
    send_cmd(ser, "N0,00")

    # Salva configurazione
    send_cmd(ser, "W")

    print("\nConfigurazione completata.")


# =========================================================
# LOOP PRINCIPALE RFID
# =========================================================


def run_reader(
    stop_event: Optional[threading.Event] = None,
    on_tag: Optional[Callable[[str], None]] = None,
) -> None:
    """
    Avvia il lettore RFID.
    """

    global PORT

    PORT = get_port()

    if stop_event is None:
        stop_event = threading.Event()

    print("\n===================================")
    print("LETTORE RFID UHF")
    print("===================================")

    print("Porta seriale:", PORT)
    print("Baudrate:", BAUD)

    print("\nCONFIG:")
    print("RF_POWER =", RF_POWER)
    print("SCAN_INTERVAL =", SCAN_INTERVAL)
    print("SERIAL_TIMEOUT =", SERIAL_TIMEOUT)
    print("SHOW_ONLY_UNIQUE_TAGS =", SHOW_ONLY_UNIQUE_TAGS)
    print("UNIQUE_TAG_RESET_SECONDS =", UNIQUE_TAG_RESET_SECONDS)

    try:

        with serial.Serial(
            PORT,
            BAUD,
            timeout=SERIAL_TIMEOUT
        ) as ser:

            # Pulizia buffer
            ser.reset_input_buffer()
            ser.reset_output_buffer()

            # =============================================
            # TEST COMUNICAZIONE
            # =============================================

            print("\n===================================")
            print("TEST COMUNICAZIONE")
            print("===================================")

            send_cmd(ser, "V")
            send_cmd(ser, "S")

            # =============================================
            # CONFIGURAZIONE RFID
            # =============================================

            configure_reader(ser)

            # =============================================
            # AVVIO SCANSIONE
            # =============================================

            print("\n===================================")
            print("SCANSIONE RFID ATTIVA")
            print("===================================")

            print("Avvicina un tag RFID UHF...\n")

            buffer = ""

            # Timer inventory
            last_inventory = 0.0

            # =============================================
            # LOOP CONTINUO
            # =============================================

            while not stop_event.is_set():

                now = time.time()

                # Inventory periodica
                if now - last_inventory >= SCAN_INTERVAL:

                    ser.write(b"\nU\r")
                    ser.flush()

                    last_inventory = now

                # Lettura seriale
                data = ser.read(1024).decode(
                    "ascii",
                    errors="ignore"
                )

                if data:
                    buffer += data

                # =========================================
                # PARSING LINEE
                # =========================================

                while "\n" in buffer or "\r" in buffer:

                    if "\n" in buffer:
                        line, buffer = buffer.split(
                            "\n",
                            1
                        )
                    else:
                        line, buffer = buffer.split(
                            "\r",
                            1
                        )

                    tag = parse_tag(line)

                    if not tag:
                        continue

                    # Filtro unici
                    if not should_show_tag(tag):
                        continue

                    print("\n==============================")
                    print("TAG RFID TROVATO")
                    print("==============================")
                    print("EPC:", tag)

                    # Callback
                    if on_tag is not None:

                        try:
                            on_tag(tag)

                        except Exception as exc:

                            print(
                                "Errore callback RFID:",
                                exc
                            )

    except serial.SerialException as exc:

        print("\nErrore seriale RFID:")
        print(exc)

    except KeyboardInterrupt:

        print("\nStop manuale lettore RFID.")

    finally:

        try:
            if "ser" in locals():

                # Stop inventory
                ser.write(b"\nu\r")
                ser.flush()

        except Exception:
            pass

        print("\nLettore RFID fermato.")


# =========================================================
# MAIN
# =========================================================


def main() -> None:
    """
    Avvio manuale terminale.
    """

    parser = argparse.ArgumentParser(
        description="RFID UHF Reader"
    )

    parser.add_argument(
        "--run-seconds",
        type=float,
        default=None,
        help="Durata esecuzione in secondi."
    )

    args = parser.parse_args()

    stop_event = threading.Event()

    # Modalità continua
    if args.run_seconds is None:

        run_reader(
            stop_event=stop_event
        )

        return

    # Modalità timeout
    timer = threading.Timer(
        args.run_seconds,
        stop_event.set
    )

    timer.start()

    try:

        run_reader(
            stop_event=stop_event
        )

    finally:

        timer.cancel()


# =========================================================
# ENTRYPOINT
# =========================================================

if __name__ == "__main__":
    main()