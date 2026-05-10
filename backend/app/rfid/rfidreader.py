#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from portfinder import get_port
import serial
import time

PORT = get_port()
BAUD = 38400


def send_cmd(ser, cmd, wait=0.15):
    payload = b"\n" + cmd.encode("ascii") + b"\r"
    print("TX:", payload)

    ser.write(payload)
    ser.flush()

    time.sleep(wait)

    n = ser.in_waiting
    data = ser.read(n if n else 1)

    try:
        text = data.decode("ascii", errors="ignore")
    except:
        text = str(data)

    if text:
        print("RX:", repr(text))

    return text


def main():
    print("Apro porta seriale...")
    with serial.Serial(PORT, BAUD, timeout=0.2) as ser:

        # pulizia buffer
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        print("\n=== TEST COMUNICAZIONE ===")
        send_cmd(ser, "V")
        send_cmd(ser, "S")

        print("\n=== CONFIGURAZIONE ===")

        # STOP inventory (sicurezza)
        send_cmd(ser, "u")

        # prova comando alternativo potenza
        print("Provo N0...")
        send_cmd(ser, "N0,1B")

        # prova anche questi fallback
        send_cmd(ser, "N1,1B")
        send_cmd(ser, "N1,19")
        send_cmd(ser, "N1,14")

        # opzionale: salva config
        send_cmd(ser, "W")

        print("\n=== AVVIO INVENTORY ===")
        ser.reset_input_buffer()

        # start inventory
        ser.write(b"\nU\r")
        ser.flush()

        print("\nAvvicina un tag UHF (pochi cm!)...\n")

        try:
            buffer = ""

            while True:
                ser.write(b"\nU\r")
                ser.flush()

                time.sleep(0.2)

                data = ser.read(256).decode("ascii", errors="ignore")
                buffer += data

                while "\n" in buffer or "\r" in buffer:
                    if "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                    else:
                        line, buffer = buffer.split("\r", 1)

                    line = line.strip()

                    if line.startswith("U") and len(line) > 5:
                        epc = line[1:]
                        print("TAG:", epc)

        except KeyboardInterrupt:
            print("\nStop inventory...")
            ser.write(b"\nu\r")


if __name__ == "__main__":
    main()