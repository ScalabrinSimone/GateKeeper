"""Inizializzatore del database conforme allo schema in query.txt.

Questo modulo crea/ricrea `test.db` nella root del progetto con le
tabelle: `users`, `objects`, `user_devices`, `events` e gli indici.

Esempio:
    python -m app.db.init_db
"""

import sqlite3
from pathlib import Path

# Percorso del file SQLite: ../test.db (root del progetto)
DB_PATH = Path(__file__).resolve().parents[2] / "test.db"


NEW_SCHEMA = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    hash_psw TEXT NOT NULL,
    username TEXT NOT NULL,
    role TEXT CHECK(role IN ('admin', 'adult', 'child')) DEFAULT 'adult',
    uuid TEXT,
    is_active BOOLEAN DEFAULT 1,
    last_seen_at TIMESTAMP,
    current_location TEXT CHECK(current_location IN ('inside', 'outside', 'unknown')) DEFAULT 'unknown',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    rfid_tag TEXT UNIQUE NOT NULL,
    category TEXT DEFAULT 'other',
    is_essential BOOLEAN DEFAULT 0,
    alert_rules TEXT DEFAULT '{}',
    current_status TEXT CHECK(current_status IN ('inside', 'outside', 'unknown')) DEFAULT 'inside',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    device_id INTEGER NOT NULL REFERENCES devices(id),
    UNIQUE(user_id, device_id)
);

CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER REFERENCES users(id),
    event_type TEXT CHECK(event_type IN ('passage_in', 'passage_out', 'alert', 'system')) NOT NULL,
    direction TEXT CHECK(direction IN ('in', 'out')),
    detected_objects TEXT DEFAULT '[]',
    detected_users TEXT DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_events_user ON events(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_devices_rfid ON devices(rfid_tag);
"""


def init_db(path: Path = DB_PATH) -> None:
    """Crea (o ricrea) il file DB con lo schema definito in NEW_SCHEMA.

    Se esiste un DB precedente viene rimosso.
    """
    path.parent.mkdir(parents=True, exist_ok=True)

    if path.exists():
        try:
            path.unlink()
            print(f"Database precedente rimosso: {path}")
        except Exception as e:
            print(f"Impossibile rimuovere il DB esistente: {e}")

    with sqlite3.connect(path) as conn:
        conn.executescript(NEW_SCHEMA)
        conn.commit()
    print(f"Nuovo database creato: {path}")


if __name__ == "__main__":
    init_db()
