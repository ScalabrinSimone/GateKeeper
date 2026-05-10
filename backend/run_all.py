
"""Avvio unico del progetto.

Questo script:
1) inizializza il database se necessario;
2) avvia il server FastAPI/Uvicorn;
3) fa partire il lettore RFID in background tramite gli hook startup/shutdown
   definiti in `endpoint.py`.

Il thread RFID resta attivo mentre il server gestisce le richieste API.
"""

from __future__ import annotations

import argparse

import uvicorn

from app.db.init_db import init_db


def main() -> None:
    parser = argparse.ArgumentParser(description="Avvio completo del progetto")
    parser.add_argument("--host", default="0.0.0.0", help="Host del server API")
    parser.add_argument("--port", type=int, default=8000, help="Porta del server API")
    parser.add_argument(
        "--reset-db",
        action="store_true",
        help="Ricrea il database da zero prima dell'avvio",
    )
    args = parser.parse_args()

    # Garantiamo uno schema coerente prima di avviare l'API.
    init_db(force=args.reset_db)
    uvicorn.run(
        "app.api.endpoint:app",
        host="0.0.0.0",
        port=8000,
        reload=False
    )


if __name__ == "__main__":
    main()
