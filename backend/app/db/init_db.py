"""Inizializzazione del database NoSQL locale."""

from __future__ import annotations

import argparse
from pathlib import Path

from .storage import DB_PATH, init_db


def main() -> None:
    parser = argparse.ArgumentParser(description="Inizializza il database NoSQL locale")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Ricrea il database da zero",
    )
    args = parser.parse_args()

    init_db(force=args.force)
    print(f"Database NoSQL pronto: {DB_PATH}")


if __name__ == "__main__":
    main()
