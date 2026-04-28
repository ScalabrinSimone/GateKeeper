"""Inizializzatore semplice del database per il progetto di test.

Questo script crea un file SQLite `test.db` (nella root del progetto)
con tre tabelle: `utenti`, `dispositivi` e `log_accessi`.

Esempio di esecuzione: `python -m app.db.init_db`
"""

import sqlite3
from pathlib import Path

# Percorso del file SQLite: ../test.db (root del progetto)
DB_PATH = Path(__file__).resolve().parents[2] / "test.db"

# Schema SQL, mantenuto leggibile
SCHEMA = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS utenti (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    api_token TEXT
);

CREATE TABLE IF NOT EXISTS dispositivi (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    tipo TEXT,
    owner_id INTEGER NOT NULL,
    FOREIGN KEY(owner_id) REFERENCES utenti(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS log_accessi (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dispositivo_id INTEGER NOT NULL,
    utente_id INTEGER,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
    action TEXT,
    FOREIGN KEY(dispositivo_id) REFERENCES dispositivi(id) ON DELETE CASCADE,
    FOREIGN KEY(utente_id) REFERENCES utenti(id)
);
"""


def init_db(path: Path = DB_PATH) -> None:
    """Crea il file DB e le tabelle se non esistono.

    Usa un context manager per chiudere la connessione automaticamente.
    """
    # assicurati che la cartella esista
    path.parent.mkdir(parents=True, exist_ok=True)

    # se esiste un DB precedente lo rimuoviamo per ricrearne uno nuovo
    if path.exists():
        try:
            path.unlink()
            print(f"Database precedente rimosso: {path}")
        except Exception as e:
            print(f"Impossibile rimuovere il DB esistente: {e}")

    # nuovo schema conforme alla struttura richiesta dall'utente
    NEW_SCHEMA = """
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS user_device (
        association_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        device_id INTEGER NOT NULL,
        UNIQUE(user_id, device_id),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        device_id INTEGER NOT NULL,
        action TEXT NOT NULL CHECK(action IN ('ENTRATO','USCITO')),
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(device_id) REFERENCES devices(id) ON DELETE CASCADE
    );
    """

    with sqlite3.connect(path) as conn:
        cur = conn.cursor()
        cur.executescript(NEW_SCHEMA)
        conn.commit()
    print(f"Nuovo database creato: {path}")


if __name__ == "__main__":
    init_db()
