"""Avvio unico del progetto.

Questo script:
1) inizializza il database NoSQL locale;
2) avvia lo scanner BLE in un thread separato;
3) avvia il server FastAPI/Uvicorn;
4) lascia il lettore RFID gestito dagli hook startup/shutdown definiti in
   `endpoint.py`.
"""

from __future__ import annotations

import argparse
import threading
import time

import uvicorn

from app.ble import blescanner
from app.db.init_db import init_db

# =========================================================
# THREAD GLOBALI
# =========================================================

bleStopEvent = threading.Event()

bleThread: threading.Thread | None = None

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
# THREAD BLE
# =========================================================


def startBleThread() -> None:
    """Avvia thread scanner BLE."""

    global bleThread

    if bleThread is not None and bleThread.is_alive():

        log(
            "INFO",
            "Thread BLE già attivo"
        )

        return

    bleStopEvent.clear()

    bleThread = threading.Thread(
        target=blescanner.runScanner,
        kwargs={
            "stopEvent": bleStopEvent
        },
        daemon=True,
        name="ble-scanner-thread"
    )

    bleThread.start()

    log(
        "OK",
        "Thread BLE avviato"
    )


def stopBleThread() -> None:
    """Ferma scanner BLE."""

    global bleThread

    bleStopEvent.set()

    if bleThread is not None:

        bleThread.join(timeout=5)

        bleThread = None

    log(
        "INFO",
        "Thread BLE fermato"
    )


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
        "--seed-test",
        action="store_true",
        help="Popola un account di test (utente: test / password: test1234)"
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
        from app.db import models as gk_models
        from app.security import tokens as gk_tokens

        gk_tokens.reset_secret()
        new_state = gk_models.factory_reset_all()
        log("INFO", f"Factory reset eseguito. Codice: {new_state.get('factory_code')}")

    if args.seed_test:
        # Esegue lo script di seed via subprocess per non sporcare lo stato qui.
        import runpy
        from pathlib import Path

        seed_path = Path(__file__).resolve().parent / "seed_test_user.py"
        if seed_path.exists():
            log("INFO", "Eseguo seed account di test")
            runpy.run_path(str(seed_path), run_name="__main__")
        else:
            log("WARN", f"Script di seed non trovato: {seed_path}")

    startBleThread()

    try:
        printSection("SERVER API")

        log(
            "INFO",
            "Avvio server FastAPI/Uvicorn"
        )

        uvicorn.run(
            "app.api.endpoint:app",
            host=args.host,
            port=args.port,
            reload=False
        )

    finally:
        stopBleThread()


# =========================================================
# ENTRY POINT
# =========================================================


if __name__ == "__main__":
    main()