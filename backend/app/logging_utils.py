"""Routing dei log per componente.

Quando si lancia il backend con `--split-logs` (o `GK_SPLIT_LOGS=1`)
ogni messaggio stampato con `print(...)` viene anche scritto su file
separati in `backend/logs/`, uno per componente (rfid, ble, qr, boot,
discovery, api, generic).

Il componente è dedotto dal prefisso `[NOME]` della riga:
- `[RFID] ...`      → logs/rfid.log
- `[BLE]  ...`      → logs/ble.log
- `[QR]   ...`      → logs/qr.log
- `[BOOT] ...`      → logs/boot.log
- `[DISCOVERY] ...` → logs/discovery.log
- altrimenti        → logs/api.log

L'output continua a comparire anche su stdout: così potete fare
`Get-Content -Wait .\backend\logs\rfid.log` (PowerShell) o
`tail -f backend/logs/rfid.log` (Linux/macOS) in finestre/terminali
separati per ottenere un'esperienza "multi-pannello".
"""

from __future__ import annotations

import os
import re
import sys
import threading
from datetime import datetime
from pathlib import Path
from typing import IO, Dict, Optional


_PREFIX_RE = re.compile(r"\[([A-Z]+)\]")

_LOGS_DIR = Path(__file__).resolve().parents[1] / "logs"
_LOCK = threading.Lock()
_FILES: Dict[str, IO[str]] = {}


def _component_for(line: str) -> str:
    """Estrae il primo prefisso `[XXX]` come nome componente."""
    # `print()` aggiunge \n alla fine, ma più chiamate possono accodare
    # frammenti: ci basta il primo match.
    match = _PREFIX_RE.search(line)
    if not match:
        return "api"
    name = match.group(1).lower()
    # Normalizziamo alcuni alias.
    if name in ("rfid", "ble", "qr", "boot", "discovery", "api"):
        return name
    return "generic"


def _open_file(component: str) -> IO[str]:
    """Apre (memoizzato) il file di log del componente, in append."""
    _LOGS_DIR.mkdir(parents=True, exist_ok=True)
    fp = _FILES.get(component)
    if fp is None or fp.closed:
        path = _LOGS_DIR / f"{component}.log"
        fp = path.open("a", encoding="utf-8", buffering=1)
        # Marca di inizio sessione per leggibilità nei terminali "tail".
        stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        fp.write(f"\n=== [{stamp}] sessione avviata ===\n")
        _FILES[component] = fp
    return fp


class _TeeStream:
    """Stream wrapper che duplica la scrittura su stdout + file per componente."""

    def __init__(self, original: IO[str]):
        self._original = original
        self._buffer: str = ""

    # I/O standard ---------------------------------------------------------
    def write(self, data: str) -> int:
        if not data:
            return 0
        # Scriviamo subito sul terminale.
        try:
            self._original.write(data)
        except Exception:
            pass
        with _LOCK:
            self._buffer += data
            # Splittiamo per newline così l'instradamento avviene per riga.
            while "\n" in self._buffer:
                line, self._buffer = self._buffer.split("\n", 1)
                if not line.strip():
                    continue
                component = _component_for(line)
                try:
                    fp = _open_file(component)
                    fp.write(line + "\n")
                except Exception:
                    # I log sono best-effort: non vogliamo che un errore
                    # qui blocchi il backend.
                    pass
        return len(data)

    def flush(self) -> None:
        try:
            self._original.flush()
        except Exception:
            pass
        with _LOCK:
            for fp in _FILES.values():
                try:
                    fp.flush()
                except Exception:
                    pass

    # Pass-through di attributi vari richiesti da terze parti --------------
    def isatty(self) -> bool:
        try:
            return self._original.isatty()
        except Exception:
            return False

    def fileno(self) -> int:
        return self._original.fileno()

    def __getattr__(self, item: str):
        return getattr(self._original, item)


_INSTALLED = False


def install_split_logs(force: Optional[bool] = None) -> Path:
    """Attiva il routing dei log su file separati.

    Restituisce la directory dei log per comodità (es. per stamparla
    al boot del backend).
    """
    global _INSTALLED
    if _INSTALLED:
        return _LOGS_DIR

    enabled = force if force is not None else os.environ.get("GK_SPLIT_LOGS", "").strip() in (
        "1",
        "true",
        "True",
        "yes",
    )
    if not enabled:
        return _LOGS_DIR

    sys.stdout = _TeeStream(sys.stdout)  # type: ignore[assignment]
    sys.stderr = _TeeStream(sys.stderr)  # type: ignore[assignment]
    _INSTALLED = True

    # Stampiamo un primo banner così l'utente vede subito dove guardare.
    print(f"[BOOT] OK     Split logs attivo. Cartella: {_LOGS_DIR}")
    return _LOGS_DIR
