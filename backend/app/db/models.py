
"""Funzioni di accesso al database SQLite.

Questo modulo contiene CRUD completi per tutte le tabelle usate dal progetto:
- users
- devices
- user_devices
- logs
- events

Le funzioni ritornano dizionari Python o `sqlite3.Row` già convertibili
facilmente in JSON dalle API FastAPI.
"""

from __future__ import annotations

import json
import sqlite3
from pathlib import Path
from typing import Any, Dict, List, Optional
from uuid import uuid4

from werkzeug.security import generate_password_hash

# Il file DB vive nella stessa cartella dei sorgenti.
DB_PATH = Path(__file__).resolve().with_name("test.db")


# --------------------------------------------------------------------------------------
# Utility interne
# --------------------------------------------------------------------------------------
def _connect() -> sqlite3.Connection:
    """Apre una connessione a SQLite con foreign key abilitate.

    `timeout` è leggermente alto per ridurre gli errori di lock quando:
    - il server FastAPI gestisce più richieste contemporaneamente;
    - il lettore RFID gira in thread separato e scrive sul DB.
    """
    conn = sqlite3.connect(DB_PATH, timeout=30)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def _row_to_dict(row: Optional[sqlite3.Row]) -> Optional[Dict[str, Any]]:
    """Converte una riga SQLite in dizionario Python."""
    return dict(row) if row is not None else None


def _rows_to_dicts(rows: List[sqlite3.Row]) -> List[Dict[str, Any]]:
    """Converte una lista di righe SQLite in lista di dizionari."""
    return [dict(row) for row in rows]


def _json_text(value: Any) -> str:
    """Trasforma un valore Python in stringa JSON.

    Se il valore è già una stringa valida JSON, viene lasciato invariato.
    Altrimenti viene serializzato.
    """
    if value is None:
        return "[]"
    if isinstance(value, str):
        try:
            json.loads(value)
            return value
        except Exception:
            return json.dumps(value, ensure_ascii=False)
    return json.dumps(value, ensure_ascii=False)


def _ensure_user_exists(user_id: int) -> None:
    """Verifica che un utente esista prima di creare relazioni o log."""
    if get_user_by_id(user_id) is None:
        raise ValueError("user not found")


def _ensure_device_exists(device_id: int) -> None:
    """Verifica che un dispositivo esista prima di creare relazioni o log."""
    if get_device_by_id(device_id) is None:
        raise ValueError("device not found")


def _validate_choice(value: Optional[str], allowed: tuple[str, ...], field_name: str, default: Optional[str] = None) -> str:
    """Valida una scelta testuale contro un elenco di valori ammessi."""
    if value is None:
        if default is None:
            raise ValueError(f"{field_name} is required")
        return default
    if value not in allowed:
        raise ValueError(f"{field_name} must be one of {allowed}")
    return value


# --------------------------------------------------------------------------------------
# USERS
# --------------------------------------------------------------------------------------
def create_user(
    username: str,
    password: str,
    email: Optional[str] = None,
    role: str = "adult",
    uuid_value: Optional[str] = None,
    is_active: bool = True,
    last_seen_at: Optional[str] = None,
    current_location: str = "unknown",
) -> int:
    """Crea un utente.

    La firma mantiene compatibilità con il vecchio codice:
    - `create_user(username, password)` continua a funzionare.
    - `email` è opzionale e, se non fornita, viene generata automaticamente.
    """
    if not username.strip():
        raise ValueError("username is required")
    if not password:
        raise ValueError("password is required")

    role = _validate_choice(role, ("admin", "adult", "child"), "role", default="adult")
    current_location = _validate_choice(
        current_location,
        ("inside", "outside", "unknown"),
        "current_location",
        default="unknown",
    )

    if email is None or not email.strip():
        email = f"{username.strip().lower()}.{uuid4().hex[:8]}@local.invalid"

    if uuid_value is None:
        uuid_value = str(uuid4())

    pw_hash = generate_password_hash(password)

    try:
        with _connect() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                INSERT INTO users
                    (email, hash_psw, username, role, uuid, is_active, last_seen_at, current_location)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    email.strip().lower(),
                    pw_hash,
                    username.strip(),
                    role,
                    uuid_value,
                    1 if is_active else 0,
                    last_seen_at,
                    current_location,
                ),
            )
            conn.commit()
            return int(cur.lastrowid)
    except sqlite3.IntegrityError as exc:
        raise ValueError("email or username already exists") from exc


def list_users(
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_location: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Restituisce tutti gli utenti, con filtri opzionali."""
    q = """
        SELECT id, email, username, role, uuid, is_active, last_seen_at, current_location, created_at
        FROM users
    """
    params: List[Any] = []
    filters: List[str] = []

    if role is not None:
        role = _validate_choice(role, ("admin", "adult", "child"), "role")
        filters.append("role = ?")
        params.append(role)

    if is_active is not None:
        filters.append("is_active = ?")
        params.append(1 if is_active else 0)

    if current_location is not None:
        current_location = _validate_choice(
            current_location,
            ("inside", "outside", "unknown"),
            "current_location",
        )
        filters.append("current_location = ?")
        params.append(current_location)

    if filters:
        q += " WHERE " + " AND ".join(filters)

    q += " ORDER BY id"

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return _rows_to_dicts(cur.fetchall())


def get_user_by_id(user_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un utente per id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, email, username, role, uuid, is_active, last_seen_at, current_location, created_at
            FROM users
            WHERE id = ?
            """,
            (user_id,),
        )
        return _row_to_dict(cur.fetchone())


def get_user_by_username(username: str) -> Optional[Dict[str, Any]]:
    """Recupera un utente per username."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, email, username, role, uuid, is_active, last_seen_at, current_location, created_at
            FROM users
            WHERE username = ?
            """,
            (username,),
        )
        return _row_to_dict(cur.fetchone())


def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Recupera un utente per email."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, email, username, role, uuid, is_active, last_seen_at, current_location, created_at
            FROM users
            WHERE email = ?
            """,
            (email.strip().lower(),),
        )
        return _row_to_dict(cur.fetchone())


def update_user(
    user_id: int,
    username: Optional[str] = None,
    email: Optional[str] = None,
    password: Optional[str] = None,
    role: Optional[str] = None,
    uuid_value: Optional[str] = None,
    is_active: Optional[bool] = None,
    last_seen_at: Optional[str] = None,
    current_location: Optional[str] = None,
) -> bool:
    """Aggiorna un utente esistente.

    Restituisce True se la riga è stata modificata.
    """
    fields: List[str] = []
    params: List[Any] = []

    if username is not None:
        if not username.strip():
            raise ValueError("username cannot be empty")
        fields.append("username = ?")
        params.append(username.strip())

    if email is not None:
        if not email.strip():
            raise ValueError("email cannot be empty")
        fields.append("email = ?")
        params.append(email.strip().lower())

    if password is not None:
        if not password:
            raise ValueError("password cannot be empty")
        fields.append("hash_psw = ?")
        params.append(generate_password_hash(password))

    if role is not None:
        role = _validate_choice(role, ("admin", "adult", "child"), "role")
        fields.append("role = ?")
        params.append(role)

    if uuid_value is not None:
        fields.append("uuid = ?")
        params.append(uuid_value)

    if is_active is not None:
        fields.append("is_active = ?")
        params.append(1 if is_active else 0)

    if last_seen_at is not None:
        fields.append("last_seen_at = ?")
        params.append(last_seen_at)

    if current_location is not None:
        current_location = _validate_choice(
            current_location,
            ("inside", "outside", "unknown"),
            "current_location",
        )
        fields.append("current_location = ?")
        params.append(current_location)

    if not fields:
        raise ValueError("no fields provided for update")

    params.append(user_id)

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(f"UPDATE users SET {', '.join(fields)} WHERE id = ?", params)
        conn.commit()
        return cur.rowcount > 0


def delete_user(user_id: int) -> bool:
    """Elimina un utente. Le relazioni collegate vengono rimosse tramite cascade."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
        return cur.rowcount > 0


# --------------------------------------------------------------------------------------
# DEVICES
# --------------------------------------------------------------------------------------
def create_device(
    name: str,
    rfid_tag: Optional[str] = None,
    category: str = "other",
    is_essential: bool = False,
    alert_rules: Any = "{}",
    current_status: str = "inside",
) -> int:
    """Crea un dispositivo.

    La firma è compatibile con il vecchio codice:
    - `create_device(name)` continua a funzionare;
    - `rfid_tag` può essere passato oppure generato automaticamente.
    """
    if not name.strip():
        raise ValueError("name is required")

    current_status = _validate_choice(
        current_status,
        ("inside", "outside", "unknown"),
        "current_status",
        default="inside",
    )

    if rfid_tag is None or not str(rfid_tag).strip():
        rfid_tag = f"RFID-{uuid4().hex[:12]}"

    try:
        with _connect() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                INSERT INTO devices
                    (name, rfid_tag, category, is_essential, alert_rules, current_status)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    name.strip(),
                    str(rfid_tag).strip(),
                    category,
                    1 if is_essential else 0,
                    _json_text(alert_rules),
                    current_status,
                ),
            )
            conn.commit()
            return int(cur.lastrowid)
    except sqlite3.IntegrityError as exc:
        raise ValueError("rfid_tag already exists") from exc


def list_devices(
    category: Optional[str] = None,
    current_status: Optional[str] = None,
    is_essential: Optional[bool] = None,
) -> List[Dict[str, Any]]:
    """Restituisce tutti i dispositivi, con filtri opzionali."""
    q = """
        SELECT id, name, rfid_tag, category, is_essential, alert_rules, current_status, created_at
        FROM devices
    """
    params: List[Any] = []
    filters: List[str] = []

    if category is not None:
        filters.append("category = ?")
        params.append(category)

    if current_status is not None:
        current_status = _validate_choice(
            current_status,
            ("inside", "outside", "unknown"),
            "current_status",
        )
        filters.append("current_status = ?")
        params.append(current_status)

    if is_essential is not None:
        filters.append("is_essential = ?")
        params.append(1 if is_essential else 0)

    if filters:
        q += " WHERE " + " AND ".join(filters)

    q += " ORDER BY id"

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return _rows_to_dicts(cur.fetchall())


def get_device_by_id(device_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un dispositivo per id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, name, rfid_tag, category, is_essential, alert_rules, current_status, created_at
            FROM devices
            WHERE id = ?
            """,
            (device_id,),
        )
        return _row_to_dict(cur.fetchone())


def get_device_by_rfid_tag(rfid_tag: str) -> Optional[Dict[str, Any]]:
    """Recupera un dispositivo tramite RFID tag."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, name, rfid_tag, category, is_essential, alert_rules, current_status, created_at
            FROM devices
            WHERE rfid_tag = ?
            """,
            (rfid_tag,),
        )
        return _row_to_dict(cur.fetchone())


def update_device(
    device_id: int,
    name: Optional[str] = None,
    rfid_tag: Optional[str] = None,
    category: Optional[str] = None,
    is_essential: Optional[bool] = None,
    alert_rules: Optional[Any] = None,
    current_status: Optional[str] = None,
) -> bool:
    """Aggiorna un dispositivo esistente."""
    fields: List[str] = []
    params: List[Any] = []

    if name is not None:
        if not name.strip():
            raise ValueError("name cannot be empty")
        fields.append("name = ?")
        params.append(name.strip())

    if rfid_tag is not None:
        if not str(rfid_tag).strip():
            raise ValueError("rfid_tag cannot be empty")
        fields.append("rfid_tag = ?")
        params.append(str(rfid_tag).strip())

    if category is not None:
        fields.append("category = ?")
        params.append(category)

    if is_essential is not None:
        fields.append("is_essential = ?")
        params.append(1 if is_essential else 0)

    if alert_rules is not None:
        fields.append("alert_rules = ?")
        params.append(_json_text(alert_rules))

    if current_status is not None:
        current_status = _validate_choice(
            current_status,
            ("inside", "outside", "unknown"),
            "current_status",
        )
        fields.append("current_status = ?")
        params.append(current_status)

    if not fields:
        raise ValueError("no fields provided for update")

    params.append(device_id)

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(f"UPDATE devices SET {', '.join(fields)} WHERE id = ?", params)
        conn.commit()
        return cur.rowcount > 0


def delete_device(device_id: int) -> bool:
    """Elimina un dispositivo. Le relazioni collegate vengono rimosse tramite cascade."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM devices WHERE id = ?", (device_id,))
        conn.commit()
        return cur.rowcount > 0


# --------------------------------------------------------------------------------------
# ASSOCIAZIONI USER <-> DEVICE
# --------------------------------------------------------------------------------------
def create_user_device(user_id: int, device_id: int) -> int:
    """Crea un'associazione tra utente e dispositivo."""
    _ensure_user_exists(user_id)
    _ensure_device_exists(device_id)

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT OR IGNORE INTO user_devices (user_id, device_id) VALUES (?, ?)",
            (user_id, device_id),
        )
        conn.commit()
        cur.execute(
            "SELECT id, user_id, device_id FROM user_devices WHERE user_id = ? AND device_id = ?",
            (user_id, device_id),
        )
        row = cur.fetchone()
        if row is None:
            raise ValueError("association not created")
        return int(row["id"])


def list_user_devices(
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
) -> List[Dict[str, Any]]:
    """Restituisce le associazioni utente-dispositivo, con filtri opzionali."""
    q = """
        SELECT
            ud.id AS association_id,
            ud.user_id,
            u.username,
            u.email,
            ud.device_id,
            d.name AS device_name,
            d.rfid_tag,
            d.category,
            d.current_status
        FROM user_devices ud
        JOIN users u ON u.id = ud.user_id
        JOIN devices d ON d.id = ud.device_id
    """
    params: List[Any] = []
    filters: List[str] = []

    if user_id is not None:
        filters.append("ud.user_id = ?")
        params.append(user_id)

    if device_id is not None:
        filters.append("ud.device_id = ?")
        params.append(device_id)

    if filters:
        q += " WHERE " + " AND ".join(filters)

    q += " ORDER BY ud.id"

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return _rows_to_dicts(cur.fetchall())


def get_user_device(association_id: int) -> Optional[Dict[str, Any]]:
    """Recupera una singola associazione tramite id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT
                ud.id AS association_id,
                ud.user_id,
                u.username,
                u.email,
                ud.device_id,
                d.name AS device_name,
                d.rfid_tag,
                d.category,
                d.current_status
            FROM user_devices ud
            JOIN users u ON u.id = ud.user_id
            JOIN devices d ON d.id = ud.device_id
            WHERE ud.id = ?
            """,
            (association_id,),
        )
        return _row_to_dict(cur.fetchone())


def delete_user_device(association_id: int) -> bool:
    """Elimina un'associazione user-device."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM user_devices WHERE id = ?", (association_id,))
        conn.commit()
        return cur.rowcount > 0


# --------------------------------------------------------------------------------------
# LOGS
# --------------------------------------------------------------------------------------
def create_log(
    user_id: int,
    device_id: int,
    action: str,
    created_at: Optional[str] = None,
) -> int:
    """Crea un log ingresso/uscita.

    La firma mantiene compatibilità con il vecchio codice.
    """
    _ensure_user_exists(user_id)
    _ensure_device_exists(device_id)

    action = action.strip().upper()
    if action not in ("ENTRATO", "USCITO"):
        raise ValueError("action must be 'ENTRATO' or 'USCITO'")

    try:
        with _connect() as conn:
            cur = conn.cursor()
            if created_at is None:
                cur.execute(
                    "INSERT INTO logs (user_id, device_id, action) VALUES (?, ?, ?)",
                    (user_id, device_id, action),
                )
            else:
                cur.execute(
                    "INSERT INTO logs (user_id, device_id, action, created_at) VALUES (?, ?, ?, ?)",
                    (user_id, device_id, action, created_at),
                )
            conn.commit()
            return int(cur.lastrowid)
    except sqlite3.IntegrityError as exc:
        raise ValueError("unable to create log") from exc


def list_logs(
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
    action: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Restituisce i log, con filtri opzionali."""
    q = "SELECT id, user_id, device_id, action, created_at FROM logs"
    params: List[Any] = []
    filters: List[str] = []

    if user_id is not None:
        filters.append("user_id = ?")
        params.append(user_id)

    if device_id is not None:
        filters.append("device_id = ?")
        params.append(device_id)

    if action is not None:
        action = action.strip().upper()
        if action not in ("ENTRATO", "USCITO"):
            raise ValueError("action must be 'ENTRATO' or 'USCITO'")
        filters.append("action = ?")
        params.append(action)

    if filters:
        q += " WHERE " + " AND ".join(filters)

    q += " ORDER BY id"

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return _rows_to_dicts(cur.fetchall())


def get_log_by_id(log_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un log tramite id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT id, user_id, device_id, action, created_at FROM logs WHERE id = ?",
            (log_id,),
        )
        return _row_to_dict(cur.fetchone())


def update_log(
    log_id: int,
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
    action: Optional[str] = None,
    created_at: Optional[str] = None,
) -> bool:
    """Aggiorna un log esistente."""
    fields: List[str] = []
    params: List[Any] = []

    if user_id is not None:
        _ensure_user_exists(user_id)
        fields.append("user_id = ?")
        params.append(user_id)

    if device_id is not None:
        _ensure_device_exists(device_id)
        fields.append("device_id = ?")
        params.append(device_id)

    if action is not None:
        action = action.strip().upper()
        if action not in ("ENTRATO", "USCITO"):
            raise ValueError("action must be 'ENTRATO' or 'USCITO'")
        fields.append("action = ?")
        params.append(action)

    if created_at is not None:
        fields.append("created_at = ?")
        params.append(created_at)

    if not fields:
        raise ValueError("no fields provided for update")

    params.append(log_id)

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(f"UPDATE logs SET {', '.join(fields)} WHERE id = ?", params)
        conn.commit()
        return cur.rowcount > 0


def delete_log(log_id: int) -> bool:
    """Elimina un log."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM logs WHERE id = ?", (log_id,))
        conn.commit()
        return cur.rowcount > 0


# --------------------------------------------------------------------------------------
# EVENTS
# --------------------------------------------------------------------------------------
def create_event(
    user_id: Optional[int],
    event_type: str,
    direction: Optional[str] = None,
    detected_objects: Any = "[]",
    detected_users: Any = "[]",
) -> int:
    """Crea un evento generico."""
    allowed = ("passage_in", "passage_out", "alert", "system")
    if event_type not in allowed:
        raise ValueError(f"event_type must be one of {allowed}")
    if direction is not None and direction not in ("in", "out"):
        raise ValueError("direction must be 'in' or 'out' if provided")

    if user_id is not None:
        _ensure_user_exists(user_id)

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO events (user_id, event_type, direction, detected_objects, detected_users)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                user_id,
                event_type,
                direction,
                _json_text(detected_objects),
                _json_text(detected_users),
            ),
        )
        conn.commit()
        return int(cur.lastrowid)


def list_events(
    user_id: Optional[int] = None,
    event_type: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Restituisce gli eventi, con filtri opzionali."""
    q = """
        SELECT id, user_id, event_type, direction, detected_objects, detected_users, created_at
        FROM events
    """
    params: List[Any] = []
    filters: List[str] = []

    if user_id is not None:
        filters.append("user_id = ?")
        params.append(user_id)

    if event_type is not None:
        allowed = ("passage_in", "passage_out", "alert", "system")
        if event_type not in allowed:
            raise ValueError(f"event_type must be one of {allowed}")
        filters.append("event_type = ?")
        params.append(event_type)

    if filters:
        q += " WHERE " + " AND ".join(filters)

    q += " ORDER BY id"

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(q, params)
        return _rows_to_dicts(cur.fetchall())


def get_event_by_id(event_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un evento tramite id."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, user_id, event_type, direction, detected_objects, detected_users, created_at
            FROM events
            WHERE id = ?
            """,
            (event_id,),
        )
        return _row_to_dict(cur.fetchone())


def update_event(
    event_id: int,
    user_id: Optional[int] = None,
    event_type: Optional[str] = None,
    direction: Optional[str] = None,
    detected_objects: Optional[Any] = None,
    detected_users: Optional[Any] = None,
    created_at: Optional[str] = None,
) -> bool:
    """Aggiorna un evento esistente."""
    fields: List[str] = []
    params: List[Any] = []

    if user_id is not None:
        _ensure_user_exists(user_id)
        fields.append("user_id = ?")
        params.append(user_id)

    if event_type is not None:
        allowed = ("passage_in", "passage_out", "alert", "system")
        if event_type not in allowed:
            raise ValueError(f"event_type must be one of {allowed}")
        fields.append("event_type = ?")
        params.append(event_type)

    if direction is not None:
        if direction not in ("in", "out"):
            raise ValueError("direction must be 'in' or 'out'")
        fields.append("direction = ?")
        params.append(direction)

    if detected_objects is not None:
        fields.append("detected_objects = ?")
        params.append(_json_text(detected_objects))

    if detected_users is not None:
        fields.append("detected_users = ?")
        params.append(_json_text(detected_users))

    if created_at is not None:
        fields.append("created_at = ?")
        params.append(created_at)

    if not fields:
        raise ValueError("no fields provided for update")

    params.append(event_id)

    with _connect() as conn:
        cur = conn.cursor()
        cur.execute(f"UPDATE events SET {', '.join(fields)} WHERE id = ?", params)
        conn.commit()
        return cur.rowcount > 0


def delete_event(event_id: int) -> bool:
    """Elimina un evento."""
    with _connect() as conn:
        cur = conn.cursor()
        cur.execute("DELETE FROM events WHERE id = ?", (event_id,))
        conn.commit()
        return cur.rowcount > 0
