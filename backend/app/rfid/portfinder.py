"""Trova in modo robusto la porta seriale del lettore RFID UHF.

Strategia:
1. enumera tutte le porte seriali presenti (`serial.tools.list_ports`),
2. cerca quelle con descrizione/HWID compatibile con i chip USB-seriali
   più comuni (CH340, CP210x, FTDI, PL2303, Silicon Labs, Prolific),
3. su Linux/Raspberry Pi, controlla anche i path canonici
   (/dev/ttyUSB*, /dev/ttyACM*, /dev/serial/by-id/*),
4. su Windows, prova le COM* note.

Importante: questa funzione NON solleva eccezioni. Se non trova nulla,
restituisce `None` e lascia che sia il chiamante a decidere se fare
retry, sospendersi o mostrare una notifica. Sul Raspberry questo evita
che il backend crashi quando la chiavetta RFID non è ancora collegata.
"""

from __future__ import annotations

import glob
import os
import platform
from typing import Optional

import serial.tools.list_ports

# Sotto-stringhe (lowercase) che identificano il lettore RFID.
# Mantieni l'elenco volutamente largo: copre CH340, CP210x, FTDI, Prolific,
# Silicon Labs e qualsiasi "usb serial" generico.
_KNOWN_KEYWORDS = (
    "ch340",
    "ch341",
    "ch910",
    "cp210",
    "cp2102",
    "ftdi",
    "ft232",
    "ft231",
    "pl2303",
    "prolific",
    "silicon labs",
    "silabs",
    "uart",
    "usb serial",
    "usb-serial",
    "usb to serial",
)


def _matches(text: str) -> bool:
    text = (text or "").lower()
    return any(kw in text for kw in _KNOWN_KEYWORDS)


def _list_linux_candidates() -> list[str]:
    """Path tipici su Linux/Raspberry Pi per adattatori USB-seriali."""
    candidates: list[str] = []
    candidates.extend(sorted(glob.glob("/dev/serial/by-id/*")))
    candidates.extend(sorted(glob.glob("/dev/ttyUSB*")))
    candidates.extend(sorted(glob.glob("/dev/ttyACM*")))
    candidates.extend(sorted(glob.glob("/dev/ttyAMA*")))
    candidates.extend(sorted(glob.glob("/dev/ttyS*")))
    # Rimuovi duplicati mantenendo l'ordine.
    seen: set[str] = set()
    uniq: list[str] = []
    for c in candidates:
        if c in seen:
            continue
        seen.add(c)
        uniq.append(c)
    return uniq


def _list_macos_candidates() -> list[str]:
    candidates: list[str] = []
    candidates.extend(sorted(glob.glob("/dev/tty.usbserial*")))
    candidates.extend(sorted(glob.glob("/dev/tty.SLAB_USBtoUART*")))
    candidates.extend(sorted(glob.glob("/dev/tty.usbmodem*")))
    return candidates


def get_port() -> Optional[str]:
    """Restituisce il device serial del lettore RFID, oppure `None`.

    L'ordine di preferenza è:
      - dispositivo enumerato con descrizione "nota" (CH340, CP210x, ...),
      - path canonici della piattaforma (Linux/macOS),
      - primo dispositivo "qualsiasi" enumerato (best-effort),
      - `None` se nessuna porta è disponibile.
    """
    # 1) Auto-detect via pyserial (cross-platform): match per descrizione/HWID.
    try:
        enumerated = list(serial.tools.list_ports.comports())
    except Exception:
        enumerated = []

    for port in enumerated:
        if _matches(port.description) or _matches(getattr(port, "hwid", "")):
            print(f"[RFID] Porta auto-rilevata: {port.device} ({port.description})")
            return port.device

    # 2) Fallback per OS sui path canonici.
    system = platform.system()
    if system == "Linux":
        for path in _list_linux_candidates():
            if os.path.exists(path):
                print(f"[RFID] Porta trovata su path canonico: {path}")
                return path
    elif system == "Darwin":
        for path in _list_macos_candidates():
            if os.path.exists(path):
                print(f"[RFID] Porta trovata: {path}")
                return path

    # 3) Best-effort: prendi il primo dispositivo enumerato (su Windows COMx,
    #    su Linux un /dev/tty* qualunque emerso da comports()).
    if enumerated:
        print(
            "[RFID] Nessun match esatto: provo il primo dispositivo enumerato "
            f"{enumerated[0].device} ({enumerated[0].description})"
        )
        return enumerated[0].device

    # 4) Nessuna porta disponibile.
    print(
        "[RFID] Nessuna porta seriale rilevata. Collega la chiavetta RFID "
        "e riprova; il backend continuerà a fare retry automaticamente."
    )
    return None