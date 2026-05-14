"""Factory reset eseguito direttamente sull'hub (Raspberry Pi).

Questo script:
- chiede conferma all'utente;
- svuota completamente il database;
- rigenera il `factory_code` da usare per il nuovo pairing;
- stampa il codice da inserire in app durante la nuova configurazione.

Si lancia con:
    python scripts/factory_reset.py
oppure:
    python scripts/factory_reset.py --yes
per saltare la conferma interattiva.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Aggiunge la cartella backend/ al path per importare app.*
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import models  # noqa: E402
from app.security import tokens as gk_tokens  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Factory reset GateKeeper")
    parser.add_argument("--yes", action="store_true", help="Salta la conferma interattiva")
    args = parser.parse_args()

    if not args.yes:
        print("ATTENZIONE: questa operazione cancella tutti i dati GateKeeper su questo hub.")
        answer = input("Confermi? digita FACTORY RESET: ")
        if answer.strip().upper() != "FACTORY RESET":
            print("Operazione annullata.")
            return

    gk_tokens.reset_secret()
    new_state = models.factory_reset_all()

    print()
    print("=" * 60)
    print("  FACTORY RESET COMPLETATO")
    print("=" * 60)
    print(f"  Codice di pairing: {new_state.get('factory_code')}")
    print("  Inseriscilo nell'app GateKeeper alla schermata di setup.")
    print("=" * 60)


if __name__ == "__main__":
    main()
