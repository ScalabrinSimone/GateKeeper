"""Helper semplificati per il nuovo schema richiesto dall'utente.

Tabelle gestite: `users`, `devices`, `user_device`, `logs`.
Le funzioni qui forniscono operazioni CRUD minime e ritornano
o `sqlite3.Row` o liste di dizionari per semplicità d'uso dall'API.
"""

import sqlite3
from pathlib import Path
from typing import Optional, List, Dict, Any
from werkzeug.security import generate_password_hash

# Percorso del file DB del progetto (two levels up -> project root)
DB_PATH = Path(__file__).resolve().parents[2] / "test.db"


def _connect() -> sqlite3.Connection:
    """Restituisce una connessione sqlite3 con i foreign keys abilitati."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def create_user(username: str, password: str) -> int:
    """Crea un utente nella tabella `users`.

    Solleva ValueError se lo username esiste già.
    Restituisce l'id creato.
    """
    pw_hash = generate_password_hash(password)
    try:
        with _connect() as conn:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO users (username, password_hash) VALUES (?, ?)",
                (username, pw_hash),
            )
            conn.commit()
            return cur.lastrowid
    except sqlite3.IntegrityError as e:
        # Presuppone che username abbia vincolo UNIQUE
        raise ValueError("username already exists") from e


def get_user_by_username(username: str) -> Optional[sqlite3.Row]:
    """Recupera un utente per username. Restituisce sqlite3.Row o None."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT id, username, password_hash, created_at FROM users WHERE username = ?",
            (username,),
        )
        return cur.fetchone()


def get_user_by_id(user_id: int) -> Optional[sqlite3.Row]:
    """Recupera un utente per id. Restituisce sqlite3.Row o None."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, username, created_at FROM users WHERE id = ?", (user_id,))
        return cur.fetchone()


def create_device(name: str) -> int:
    """Crea un dispositivo e restituisce il suo id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("INSERT INTO devices (name) VALUES (?)", (name,))
        conn.commit()
        return cur.lastrowid


def list_devices() -> List[Dict[str, Any]]:
    """Restituisce tutti i dispositivi come lista di dizionari."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, name, created_at FROM devices ORDER BY id")
        return [dict(row) for row in cur.fetchall()]


def associate_user_device(user_id: int, device_id: int) -> int:
    """Associa un utente a un dispositivo.

    Se l'associazione esiste già, restituisce l'id esistente.
    """
    with _connect() as conn:
        cur = conn.cursor()
        # Inserisce solo se non esiste (unique constraint su user_id,device_id)
        cur.execute(
            "INSERT OR IGNORE INTO user_device (user_id, device_id) VALUES (?, ?)",
            (user_id, device_id),
        )
        conn.commit()
        cur.execute(
            "SELECT association_id FROM user_device WHERE user_id = ? AND device_id = ?",
            (user_id, device_id),
        )
        row = cur.fetchone()
        return int(row["association_id"]) if row else 0


def create_log(user_id: int, device_id: int, action: str) -> int:
    """Inserisce un log nella tabella `logs`.

    `action` deve essere 'ENTRATO' o 'USCITO'.
    Restituisce l'id del log creato.
    """
    if action not in ("ENTRATO", "USCITO"):
        raise ValueError("action must be 'ENTRATO' or 'USCITO'")
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO logs (user_id, device_id, action) VALUES (?, ?, ?)",
            (user_id, device_id, action),
        )
        conn.commit()
        return cur.lastrowid


def list_logs(user_id: Optional[int] = None, device_id: Optional[int] = None) -> List[Dict[str, Any]]:
    """Restituisce i log con filtri opzionali per `user_id` e `device_id`."""
    q = "SELECT id, user_id, device_id, action, created_at FROM logs"
    params: List[Any] = []
    clauses: List[str] = []
    if user_id is not None:
        clauses.append("user_id = ?")
        params.append(user_id)
    if device_id is not None:
        clauses.append("device_id = ?")
        params.append(device_id)
    if clauses:
        q += " WHERE " + " AND ".join(clauses)
    q += " ORDER BY id"
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return [dict(row) for row in cur.fetchall()]
