#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Scanner BLE continuo con output terminale pulito ed elegante.

Il modulo avvia una scansione BLE continua in background e stampa nel terminale
i dispositivi rilevati. Usa una classificazione euristica basata sul nome del
dispositivo e su alcuni indizi tipici delle advertisement BLE.

Nota: il BLE non consente di identificare in modo certo una persona.
Questo scanner rileva i dispositivi vicini che trasmettono advertisement BLE
(ed evidenzia quelli che sembrano telefoni) ed è pensato come base per una
futura integrazione applicativa.
"""

from __future__ import annotations

import asyncio
import threading
import time
from dataclasses import dataclass
from typing import Optional

try:
    from bleak import BleakScanner
    from bleak.backends.device import BLEDevice
    from bleak.backends.scanner import AdvertisementData

except Exception as exc:
    BleakScanner = None
    BLEDevice = object
    AdvertisementData = object

    bleImportError = exc

else:
    bleImportError = None

# =========================================================
# CONFIGURAZIONE GLOBALE
# =========================================================

# Se True ristampa continuamente anche device già trovati
# Se False mostra solo device nuovi/unici
SHOW_ALREADY_SEEN_DEVICES = False

# Ogni quanti secondi ristampare lo stesso device
PRINT_REPEAT_SECONDS = 10.0

# Delay restart scanner BLE in caso di errore
RESTART_DELAY_SECONDS = 3.0

# Delay loop asyncio BLE
SCAN_LOOP_DELAY = 0.5

# Hint dispositivi telefono
PHONE_HINTS = (
    "iphone",
    "ipad",
    "ipod",
    "android",
    "pixel",
    "galaxy",
    "samsung",
    "huawei",
    "xiaomi",
    "redmi",
    "poco",
    "honor",
    "oppo",
    "oneplus",
    "motorola",
    "nokia",
    "sony",
    "google",
    "realme",
)

# =========================================================
# CACHE DEVICE
# =========================================================


@dataclass(frozen=True)
class SeenDevice:
    """Struttura device BLE già mostrato."""

    lastPrintTs: float
    isPhone: bool


seenDevices: dict[str, SeenDevice] = {}

seenLock = threading.Lock()

# =========================================================
# LOGGING
# =========================================================


def getTimestamp() -> str:
    return time.strftime("%H:%M:%S")


def log(level: str, message: str) -> None:
    print(f"[{getTimestamp()}] [BLE] {level:<7} {message}")


def printSection(title: str) -> None:
    line = "─" * max(8, len(title) + 2)

    print()
    print(f"┌{line}┐")
    print(f"│ {title} │")
    print(f"└{line}┘")


# =========================================================
# UTILS
# =========================================================


def normalize(text: Optional[str]) -> str:
    """Normalizza stringa."""

    return (text or "").strip().lower()


def looksLikePhone(
    device: BLEDevice,
    adv: AdvertisementData
) -> bool:
    """Heuristica identificazione telefoni."""

    candidates = [
        normalize(getattr(device, "name", None)),
        normalize(getattr(adv, "local_name", None)),
    ]

    for candidate in candidates:
        if not candidate:
            continue

        if any(hint in candidate for hint in PHONE_HINTS):
            return True

    return False


def formatManufacturerData(
    adv: AdvertisementData
) -> str:
    """Formatta manufacturer data BLE."""

    manufacturerData = getattr(
        adv,
        "manufacturer_data",
        None
    ) or {}

    if not manufacturerData:
        return "{}"

    parts: list[str] = []

    for manufacturerId, payload in manufacturerData.items():

        if isinstance(payload, (bytes, bytearray)):
            payloadRepr = payload.hex().upper()

        else:
            payloadRepr = str(payload)

        parts.append(f"{manufacturerId}:{payloadRepr}")

    return "{" + ", ".join(parts) + "}"


def shouldPrint(
    address: str,
    isPhone: bool
) -> bool:
    """Gestione stampa dispositivi BLE."""

    if SHOW_ALREADY_SEEN_DEVICES:
        return True

    now = time.time()

    with seenLock:
        previous = seenDevices.get(address)

        if previous is not None:

            if (
                previous.isPhone == isPhone
                and (
                    now - previous.lastPrintTs
                ) < PRINT_REPEAT_SECONDS
            ):
                return False

        seenDevices[address] = SeenDevice(
            lastPrintTs=now,
            isPhone=isPhone
        )

        return True


# =========================================================
# OUTPUT DEVICE
# =========================================================


def printDevice(
    device: BLEDevice,
    adv: AdvertisementData
) -> None:
    """Stampa device BLE trovato."""

    address = getattr(
        device,
        "address",
        "unknown"
    ) or "unknown"

    name = (
        getattr(device, "name", None)
        or getattr(adv, "local_name", None)
        or "sconosciuto"
    )

    rssi = getattr(adv, "rssi", None)

    serviceUuids = getattr(
        adv,
        "service_uuids",
        None
    ) or []

    manufacturerData = formatManufacturerData(adv)

    isPhone = looksLikePhone(device, adv)

    if not shouldPrint(address, isPhone):
        return

    label = (
        "TELEFONO BLE PROBABILE"
        if isPhone
        else "DISPOSITIVO BLE"
    )

    printSection(label)

    log("INFO", f"Address          : {address}")
    log("INFO", f"Nome             : {name}")

    if rssi is not None:
        log("INFO", f"RSSI             : {rssi}")

    if serviceUuids:
        log("INFO", f"Service UUIDs    : {serviceUuids}")

    log(
        "INFO",
        f"Manufacturer data: {manufacturerData}"
    )


# =========================================================
# LOOP SCANNER BLE
# =========================================================


async def scanLoop(
    stopEvent: threading.Event
) -> None:
    """Loop scansione BLE."""

    if BleakScanner is None:
        raise RuntimeError(
            f"bleak non disponibile: {bleImportError}"
        )

    def detectionCallback(
        device: BLEDevice,
        adv: AdvertisementData
    ) -> None:

        try:
            printDevice(device, adv)

        except Exception as exc:
            log(
                "ERROR",
                f"Errore gestione BLE: {exc}"
            )

    scanner = BleakScanner(
        detection_callback=detectionCallback
    )

    await scanner.start()

    printSection("SCANNER BLE ATTIVO")

    log("OK", "Scansione continua avviata")

    log(
        "INFO",
        "I device BLE verranno mostrati nel terminale"
    )

    try:
        while not stopEvent.is_set():
            await asyncio.sleep(SCAN_LOOP_DELAY)

    finally:
        await scanner.stop()


# =========================================================
# AVVIO SCANNER
# =========================================================


def runScanner(
    stopEvent: Optional[threading.Event] = None
) -> None:
    """Entry point scanner BLE."""

    if stopEvent is None:
        stopEvent = threading.Event()

    printSection("AVVIO SCANNER BLE")

    log(
        "INFO",
        "Preparazione scansione BLE continua"
    )

    while not stopEvent.is_set():

        try:
            asyncio.run(scanLoop(stopEvent))

            break

        except KeyboardInterrupt:
            log(
                "WARN",
                "Stop manuale scanner BLE"
            )

            break

        except Exception as exc:
            log(
                "ERROR",
                f"Errore scanner BLE: {exc}"
            )

            if stopEvent.is_set():
                break

            time.sleep(RESTART_DELAY_SECONDS)

    log("INFO", "Scanner BLE fermato")


# =========================================================
# AVVIO MANUALE
# =========================================================


def main() -> None:
    """Avvio manuale terminale."""

    stopEvent = threading.Event()

    try:
        runScanner(stopEvent=stopEvent)

    except KeyboardInterrupt:
        stopEvent.set()


if __name__ == "__main__":
    main()