"""Helper semplificati per lo schema definito in query.txt.

Tabelle gestite: `users`, `devices`, `user_devices`, `events`.
Le funzioni forniscono operazioni CRUD minime e ritornano
`sqlite3.Row` o liste di dizionari per semplicità d'uso dall'API.
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


def create_user(email: str, username: str, password: str, role: str = "adult", uuid: Optional[str] = None, is_active: bool = True) -> int:
    """Crea un utente nella tabella `users`.

    Solleva ValueError se l'email esiste già.
    Restituisce l'id creato.
    """
    pw_hash = generate_password_hash(password)
    try:
        with _connect() as conn:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO users (email, hash_psw, username, role, uuid, is_active) VALUES (?, ?, ?, ?, ?, ?)",
                (email, pw_hash, username, role, uuid, 1 if is_active else 0),
            )
            conn.commit()
            return cur.lastrowid
    except sqlite3.IntegrityError as e:
        # Presuppone che email abbia vincolo UNIQUE
        raise ValueError("email already exists") from e


def get_user_by_username(username: str) -> Optional[sqlite3.Row]:
    """Recupera un utente per username. Restituisce sqlite3.Row o None."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT id, email, username, hash_psw, role, uuid, is_active, last_seen_at, current_location, created_at FROM users WHERE username = ?",
            (username,),
        )
        return cur.fetchone()


def get_user_by_id(user_id: int) -> Optional[sqlite3.Row]:
    """Recupera un utente per id. Restituisce sqlite3.Row o None."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, email, username, role, uuid, is_active, last_seen_at, current_location, created_at FROM users WHERE id = ?", (user_id,))
        return cur.fetchone()


def create_device(name: str, rfid_tag: str, category: str = "other", is_essential: bool = False, alert_rules: str = "{}", current_status: str = "inside") -> int:
    """Crea un dispositivo nella tabella `devices` e restituisce il suo id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO devices (name, rfid_tag, category, is_essential, alert_rules, current_status) VALUES (?, ?, ?, ?, ?, ?)",
            (name, rfid_tag, category, 1 if is_essential else 0, alert_rules, current_status),
        )
        conn.commit()
        return cur.lastrowid


def list_devices() -> List[Dict[str, Any]]:
    """Restituisce tutti i dispositivi come lista di dizionari."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, name, rfid_tag, category, is_essential, alert_rules, current_status, created_at FROM devices ORDER BY id")
        return [dict(row) for row in cur.fetchall()]


def associate_user_device(user_id: int, device_id: int) -> int:
    """Associa un utente a un dispositivo.

    Se l'associazione esiste già, restituisce l'id esistente.
    """
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT OR IGNORE INTO user_devices (user_id, device_id) VALUES (?, ?)",
            (user_id, device_id),
        )
        conn.commit()
        cur.execute(
            "SELECT id FROM user_devices WHERE user_id = ? AND device_id = ?",
            (user_id, device_id),
        )
        row = cur.fetchone()
        return int(row["id"]) if row else 0


def create_event(user_id: Optional[int], event_type: str, direction: Optional[str] = None, detected_objects: str = "[]", detected_users: str = "[]") -> int:
    """Inserisce un evento nella tabella `events`.

    `event_type` deve essere uno dei: 'passage_in','passage_out','alert','system'.
    Restituisce l'id dell'evento creato.
    """
    allowed = ("passage_in", "passage_out", "alert", "system")
    if event_type not in allowed:
        raise ValueError(f"event_type must be one of {allowed}")
    if direction is not None and direction not in ("in", "out"):
        raise ValueError("direction must be 'in' or 'out' if provided")
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO events (user_id, event_type, direction, detected_objects, detected_users) VALUES (?, ?, ?, ?, ?)",
            (user_id, event_type, direction, detected_objects, detected_users),
        )
        conn.commit()
        return cur.lastrowid


def list_events(user_id: Optional[int] = None) -> List[Dict[str, Any]]:
    """Restituisce eventi, opzionalmente filtrati per `user_id`."""
    q = "SELECT id, user_id, event_type, direction, detected_objects, detected_users, created_at FROM events"
    params: List[Any] = []
    if user_id is not None:
        q += " WHERE user_id = ?"
        params.append(user_id)
    q += " ORDER BY id"
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return [dict(row) for row in cur.fetchall()]

"""
Elenco dei metodi presenti in questo file e descrizione sintetica:

- _connect():
    Restituisce una connessione a SQLite con `row_factory` impostato a
    `sqlite3.Row` e `PRAGMA foreign_keys = ON` abilitato.

- create_user(email, username, password, role='adult', uuid=None, is_active=True):
    Crea un nuovo utente nella tabella `users`. Usa `werkzeug.security.generate_password_hash`
    per hashare la password. Solleva `ValueError` se l'email esiste già.

- get_user_by_username(username):
    Recupera e ritorna una riga (`sqlite3.Row`) dell'utente con il dato `username`,
    oppure `None` se non trovato.

- get_user_by_id(user_id):
    Recupera e ritorna una riga (`sqlite3.Row`) dell'utente con il dato `id`,
    oppure `None` se non trovato.

- create_device(name, rfid_tag, category='other', is_essential=False, alert_rules='{}', current_status='inside'):
    Inserisce un nuovo dispositivo nella tabella `devices` e ritorna l'id creato.

- list_devices():
    Restituisce una lista di dizionari con tutti i dispositivi presenti nella tabella `devices`.

- associate_user_device(user_id, device_id):
    Associa un utente a un dispositivo nella tabella `user_devices`.
    Usa `INSERT OR IGNORE` per evitare duplicati e ritorna l'id dell'associazione.

- create_event(user_id, event_type, direction=None, detected_objects='[]', detected_users='[]'):
    Inserisce un evento nella tabella `events`. Valida `event_type` e `direction`.
    Ritorna l'id dell'evento creato; solleva `ValueError` per parametri non validi.

- list_events(user_id=None):
    Restituisce gli eventi come lista di dizionari, opzionalmente filtrati per `user_id`.

Questa sezione serve come riferimento rapido per comprendere le API di accesso al DB
implementate in questo modulo.
"""
