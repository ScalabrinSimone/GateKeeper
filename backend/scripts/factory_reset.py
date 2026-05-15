"""Factory reset completo dell'hub GateKeeper (Raspberry Pi).

Questo script lascia il Raspberry "come nuovo":

1. (opzionale) chiede conferma all'utente,
2. elimina fisicamente il file `nosql_db.json` (e gli eventuali backup
   generati da `init_db`),
3. cancella la cartella `backend/logs/` (log per-componente + pairing QR),
4. rigenera il segreto JWT (`backend/app/security/.jwt_secret`),
5. ricrea il database vuoto e genera un nuovo `factory_code`,
6. stampa il factory_code da inserire in app durante la nuova
   configurazione.

Uso:
    python scripts/factory_reset.py
oppure:
    python scripts/factory_reset.py --yes
per saltare la conferma interattiva.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

# Aggiunge la cartella backend/ al path per importare app.*
BACKEND_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_DIR))

from app.db import models  # noqa: E402
from app.db.init_db import init_db  # noqa: E402
from app.db.storage import DB_PATH  # noqa: E402
from app.security import tokens as gk_tokens  # noqa: E402


def _remove_path(path: Path) -> None:
    """Rimuove file o directory in modo idempotente."""
    if path.is_file() or path.is_symlink():
        try:
            path.unlink()
            print(f"  - rimosso file: {path}")
        except Exception as exc:
            print(f"  ! impossibile rimuovere {path}: {exc}")
    elif path.is_dir():
        try:
            shutil.rmtree(path)
            print(f"  - rimossa directory: {path}")
        except Exception as exc:
            print(f"  ! impossibile rimuovere {path}: {exc}")


def _wipe_filesystem() -> None:
    """Cancella file generati a runtime: DB, log, QR PNG, backup."""
    print("[FACTORY-RESET] pulizia filesystem...")

    # Database principale e suoi backup (init_db salva backup *_backup_*.json).
    _remove_path(DB_PATH)
    db_dir = DB_PATH.parent
    if db_dir.exists():
        for sibling in db_dir.glob(f"{DB_PATH.stem}_backup_*{DB_PATH.suffix}"):
            _remove_path(sibling)

    # Cartella logs (split logs + pairing_qr.png).
    _remove_path(BACKEND_DIR / "logs")

    # Cache Python (best-effort, riduce sorprese fra reset successivi).
    for cache in BACKEND_DIR.rglob("__pycache__"):
        _remove_path(cache)


def _regenerate_state() -> dict:
    """Rigenera segreti e database, restituisce il nuovo stato hub."""
    print("[FACTORY-RESET] rigenero segreto JWT e database...")
    gk_tokens.reset_secret()
    init_db(force=True)
    new_state = models.factory_reset_all()
    return new_state


def main() -> None:
    parser = argparse.ArgumentParser(description="Factory reset GateKeeper")
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Salta la conferma interattiva",
    )
    args = parser.parse_args()

    if not args.yes:
        print(
            "ATTENZIONE: questa operazione cancella TUTTI i dati GateKeeper "
            "su questo hub (utenti, dispositivi, log, eventi, inviti, sessioni)."
        )
        answer = input("Confermi? digita FACTORY RESET: ")
        if answer.strip().upper() != "FACTORY RESET":
            print("Operazione annullata.")
            return

    _wipe_filesystem()
    new_state = _regenerate_state()

    print()
    print("=" * 60)
    print("  FACTORY RESET COMPLETATO")
    print("=" * 60)
    print(f"  Codice di pairing: {new_state.get('factory_code')}")
    print("  Riavvia 'run_all.py' e inseriscilo nell'app GateKeeper")
    print("  alla schermata di setup (oppure usa il QR mostrato in console).")
    print("=" * 60)


if __name__ == "__main__":
    main()
