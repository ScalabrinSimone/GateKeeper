
"""Inizializzazione del database SQLite del progetto.

Il database usa uno schema coerente e completo con queste tabelle:
- users
- devices
- user_devices
- logs
- events

Se trova un vecchio database incompatibile, lo mette in backup e ne crea uno nuovo.
"""

from __future__ import annotations

import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict

DB_PATH = Path(__file__).resolve().with_name("test.db")

SCHEMA = """
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    hash_psw TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    role TEXT CHECK(role IN ('admin', 'adult', 'child')) DEFAULT 'adult',
    uuid TEXT UNIQUE,
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
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id)
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK(action IN ('ENTRATO', 'USCITO')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT CHECK(event_type IN ('passage_in', 'passage_out', 'alert', 'system')) NOT NULL,
    direction TEXT CHECK(direction IN ('in', 'out')),
    detected_objects TEXT DEFAULT '[]',
    detected_users TEXT DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_devices_rfid ON devices(rfid_tag);
CREATE INDEX IF NOT EXISTS idx_user_devices_user ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_device ON user_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_logs_user ON logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_logs_device ON logs(device_id, created_at);
CREATE INDEX IF NOT EXISTS idx_events_user ON events(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type, created_at);
"""

EXPECTED_TABLES = {
    "users": {"id", "email", "hash_psw", "username", "role", "uuid", "is_active", "last_seen_at", "current_location", "created_at"},
    "devices": {"id", "name", "rfid_tag", "category", "is_essential", "alert_rules", "current_status", "created_at"},
    "user_devices": {"id", "user_id", "device_id"},
    "logs": {"id", "user_id", "device_id", "action", "created_at"},
    "events": {"id", "user_id", "event_type", "direction", "detected_objects", "detected_users", "created_at"},
}


def _schema_snapshot(path: Path) -> Dict[str, set[str]]:
    """Ritorna un dizionario con nomi tabella -> set colonne."""
    snapshot: Dict[str, set[str]] = {}
    if not path.exists():
        return snapshot

    with sqlite3.connect(path) as conn:
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cur.fetchall()]
        for table in tables:
            cur.execute(f"PRAGMA table_info({table})")
            snapshot[table] = {row[1] for row in cur.fetchall()}
    return snapshot


def _is_compatible(path: Path) -> bool:
    """Verifica se il database già presente è compatibile con lo schema atteso."""
    snapshot = _schema_snapshot(path)
    if not snapshot:
        return False

    for table, columns in EXPECTED_TABLES.items():
        if table not in snapshot:
            return False
        if not columns.issubset(snapshot[table]):
            return False

    return True


def _backup_incompatible_db(path: Path) -> None:
    """Sposta il vecchio database incompatibile in un file di backup."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = path.with_name(f"{path.stem}_backup_{timestamp}{path.suffix}")
    path.replace(backup_path)
    print(f"Database incompatibile salvato come backup: {backup_path}")


def init_db(path: Path = DB_PATH, force: bool = False) -> None:
    """Crea il database se manca o lo rigenera se è incompatibile."""
    path.parent.mkdir(parents=True, exist_ok=True)

    if path.exists():
        if force:
            path.unlink()
            print(f"Database rimosso forzatamente: {path}")
        elif not _is_compatible(path):
            _backup_incompatible_db(path)
        else:
            print(f"Database già compatibile: {path}")
            # Applica comunque lo schema per garantire tabelle e indici.
            with sqlite3.connect(path) as conn:
                conn.executescript(SCHEMA)
                conn.commit()
            return

    with sqlite3.connect(path) as conn:
        conn.executescript(SCHEMA)
        conn.commit()
    print(f"Database creato correttamente: {path}")


if __name__ == "__main__":
    init_db()
