"""Seed script: prepara un ambiente di test "già configurato".

Esegue:
1) reset del database;
2) creazione di un admin di test (username: test, password: test1234, email: test@local.test);
3) marca l'hub come accoppiato con casa "Casa Demo";
4) crea un paio di dispositivi/eventi demo;
5) genera un invito attivo per testare il flusso di accettazione.

Usalo solo in sviluppo: serve per entrare subito in app saltando il pairing.
"""

from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path

# Permette `python seed_test_user.py` dalla cartella backend/.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.db import models  # noqa: E402
from app.db.init_db import init_db  # noqa: E402


def main() -> None:
    print("[SEED] Reset database...")
    init_db(force=True)
    models.factory_reset_all()

    print("[SEED] Creazione admin di test...")
    admin_id = models.create_user(
        username="test",
        password="test1234",
        email="test@local.test",
        role="admin",
    )

    print("[SEED] Imposto stato hub: paired = True (Casa Demo)")
    now_iso = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    models.set_hub({
        "paired": True,
        "house_name": "Casa Demo",
        "admin_user_id": admin_id,
        "paired_at": now_iso,
        "factory_code": None,
    })

    print("[SEED] Aggiungo membri demo...")
    elena_id = models.create_user(username="elena", password="elena1234", email="elena@demo.test", role="adult")
    luca_id = models.create_user(username="luca", password="luca1234", email="luca@demo.test", role="child")

    print("[SEED] Aggiungo dispositivi demo...")
    keys = models.create_device(name="Chiavi Auto", rfid_tag="RFID-TEST-001", category="keys", is_essential=True)
    umbrella = models.create_device(name="Ombrello Rosso", rfid_tag="RFID-TEST-002", category="umbrella")
    bag = models.create_device(name="Zaino Scuola", rfid_tag="RFID-TEST-003", category="bag", is_essential=True)

    models.create_user_device(admin_id, keys)
    models.create_user_device(luca_id, bag)
    models.create_user_device(elena_id, umbrella)

    print("[SEED] Aggiungo log/eventi demo...")
    models.create_log(admin_id, keys, "ENTRATO")
    models.create_log(luca_id, bag, "USCITO")

    models.create_event(
        user_id=admin_id,
        event_type="passage_in",
        direction="in",
        detected_objects=[{"rfid_tag": "RFID-TEST-001"}],
        detected_users=[{"user_id": admin_id, "username": "test"}],
    )
    models.create_event(
        user_id=luca_id,
        event_type="passage_out",
        direction="out",
        detected_objects=[{"rfid_tag": "RFID-TEST-003"}],
        detected_users=[{"user_id": luca_id, "username": "luca"}],
    )

    print("[SEED] Genero un invito demo...")
    invite = models.create_invite(admin_id, role="adult", suggested_name="Membro Demo", ttl_hours=24 * 30)
    print(f"[SEED]   token invito: {invite['token']}")

    print()
    print("=" * 60)
    print("  ACCOUNT DI TEST PRONTO")
    print("=" * 60)
    print("  Username : test")
    print("  Password : test1234")
    print("  Ruolo    : admin")
    print("  Casa     : Casa Demo")
    print("=" * 60)


if __name__ == "__main__":
    main()
