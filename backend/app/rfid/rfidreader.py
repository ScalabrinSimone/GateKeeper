#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Lettore RFID UHF seriale.

Questo modulo può essere eseguito da solo per i test manuali oppure
lanciato in un thread dal server principale. In modalità integrata:
- continua a leggere i tag RFID in background;
- non blocca le richieste API;
- accetta una callback `on_tag` per reagire ai tag letti.
"""

from __future__ import annotations

import argparse
import threading
import time
from typing import Callable, Optional

import serial

from app.rfid.portfinder import get_port

PORT = None
BAUD = 38400


def send_cmd(ser: serial.Serial, cmd: str, wait: float = 0.15) -> str:
    """Invia un comando al lettore e restituisce la risposta testuale."""
    payload = b"\n" + cmd.encode("ascii") + b"\r"
    print("TX:", payload)

    ser.write(payload)
    ser.flush()

    time.sleep(wait)

    n = ser.in_waiting
    data = ser.read(n if n else 1)

    try:
        text = data.decode("ascii", errors="ignore")
    except Exception:
        text = str(data)

    if text:
        print("RX:", repr(text))

    return text


def _parse_tag_from_line(line: str) -> Optional[str]:
    """Estrae il tag EPC dalla riga ricevuta dal lettore."""
    line = line.strip()
    if line.startswith("U") and len(line) > 5:
        return line[1:].strip()
    return None


def run_reader(
    stop_event: Optional[threading.Event] = None,
    on_tag: Optional[Callable[[str], None]] = None,
    inventory_delay: float = 0.2,
) -> None:
    """Avvia il ciclo di lettura RFID.

    Parametri:
    - stop_event: evento thread-safe usato per fermare il loop.
    - on_tag: callback eseguita ogni volta che viene trovato un tag valido.
    - inventory_delay: pausa tra un ciclo inventory e il successivo.
    """
    global PORT
    PORT = get_port()

    if stop_event is None:
        stop_event = threading.Event()

    print("Apro porta seriale:", PORT)

    try:
        with serial.Serial(PORT, BAUD, timeout=0.2) as ser:
            # Pulizia buffer iniziale.
            ser.reset_input_buffer()
            ser.reset_output_buffer()

            print("\n=== TEST COMUNICAZIONE ===")
            send_cmd(ser, "V")
            send_cmd(ser, "S")

            print("\n=== CONFIGURAZIONE ===")
            send_cmd(ser, "u")  # stop inventory per sicurezza
            print("Provo N0...")
            send_cmd(ser, "N0,1B")
            send_cmd(ser, "N1,1B")
            send_cmd(ser, "N1,19")
            send_cmd(ser, "N1,14")
            send_cmd(ser, "W")  # salva configurazione

            print("\n=== AVVIO INVENTORY ===")
            ser.reset_input_buffer()

            # Avvio inventory.
            ser.write(b"\nU\r")
            ser.flush()

            print("Avvicina un tag UHF (pochi cm!)...")

            buffer = ""

            while not stop_event.is_set():
                # Richiesta inventory periodica.
                ser.write(b"\nU\r")
                ser.flush()

                time.sleep(inventory_delay)

                data = ser.read(256).decode("ascii", errors="ignore")
                buffer += data

                while "\n" in buffer or "\r" in buffer:
                    if "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                    else:
                        line, buffer = buffer.split("\r", 1)

                    tag = _parse_tag_from_line(line)
                    if tag:
                        print("TAG:", tag)
                        if on_tag is not None:
                            try:
                                on_tag(tag)
                            except Exception as callback_exc:
                                print("Errore callback RFID:", callback_exc)

    except serial.SerialException as exc:
        print("Errore seriale RFID:", exc)
    except KeyboardInterrupt:
        print("\nStop manuale del lettore RFID...")
    finally:
        try:
            if 'ser' in locals():
                ser.write(b"\nu\r")
                ser.flush()
        except Exception:
            pass
        print("Lettore RFID fermato.")


def main() -> None:
    """Avvio manuale da riga di comando."""
    parser = argparse.ArgumentParser(description="Lettore RFID UHF seriale")
    parser.add_argument(
        "--run-seconds",
        type=float,
        default=None,
        help="Durata in secondi; se omessa il lettore rimane attivo finché non lo interrompi.",
    )
    args = parser.parse_args()

    stop_event = threading.Event()

    if args.run_seconds is None:
        run_reader(stop_event=stop_event)
        return

    timer = threading.Timer(args.run_seconds, stop_event.set)
    timer.start()
    try:
        run_reader(stop_event=stop_event)
    finally:
        timer.cancel()


if __name__ == "__main__":
    main()
