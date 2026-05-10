"""Funzioni di accesso al database NoSQL locale.

Il progetto è stato migrato da SQLite a un archivio documentale su file JSON.
Le API restano invariate, ma la persistenza ora è NoSQL e autonoma.

Collezioni gestite:
- users
- devices
- user_devices
- logs
- events
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

from werkzeug.security import generate_password_hash

from .storage import (
    DB_LOCK,
    DB_PATH as STORAGE_DB_PATH,
    delete_by_id,
    find_by_id,
    filter_records,
    init_db,
    load_db,
    next_id,
    save_db,
    to_json_text,
)

# Manteniamo il nome DB_PATH per compatibilità con eventuali riferimenti esterni.
DB_PATH = STORAGE_DB_PATH


# --------------------------------------------------------------------------------------
# Utility interne
# --------------------------------------------------------------------------------------
def _now_iso() -> str:
    """Timestamp ISO 8601 in UTC."""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _validate_choice(
    value: Optional[str],
    allowed: tuple[str, ...],
    field_name: str,
    default: Optional[str] = None,
) -> str:
    """Valida una scelta testuale contro un elenco di valori ammessi."""
    if value is None:
        if default is None:
            raise ValueError(f"{field_name} is required")
        return default

    if value not in allowed:
        raise ValueError(f"{field_name} must be one of {allowed}")

    return value


def _ensure_user_exists(user_id: int) -> None:
    """Verifica che un utente esista prima di creare relazioni o log."""
    if get_user_by_id(user_id) is None:
        raise ValueError("user not found")


def _ensure_device_exists(device_id: int) -> None:
    """Verifica che un dispositivo esista prima di creare relazioni o log."""
    if get_device_by_id(device_id) is None:
        raise ValueError("device not found")


def _unique_exists(records: List[Dict[str, Any]], field: str, value: Any, *, exclude_id: Optional[int] = None) -> bool:
    """Controlla se un valore è già usato da un altro record."""
    for record in records:
        if exclude_id is not None and record.get("id") == exclude_id:
            continue
        if record.get(field) == value:
            return True
    return False


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
    """Crea un utente."""
    if not username or not username.strip():
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

    username = username.strip()
    if email is None or not str(email).strip():
        email = f"{username.lower()}.{uuid4().hex[:8]}@local.invalid"
    email = str(email).strip().lower()

    if uuid_value is None or not str(uuid_value).strip():
        uuid_value = str(uuid4())
    else:
        uuid_value = str(uuid_value).strip()

    pw_hash = generate_password_hash(password)

    with DB_LOCK:
        init_db()
        db = load_db()
        users = db["users"]

        if _unique_exists(users, "username", username):
            raise ValueError("email or username already exists")
        if _unique_exists(users, "email", email):
            raise ValueError("email or username already exists")
        if _unique_exists(users, "uuid", uuid_value):
            raise ValueError("uuid already exists")

        user_id = next_id(db, "users")
        users.append(
            {
                "id": user_id,
                "email": email,
                "hash_psw": pw_hash,
                "username": username,
                "role": role,
                "uuid": uuid_value,
                "is_active": bool(is_active),
                "last_seen_at": last_seen_at,
                "current_location": current_location,
                "created_at": _now_iso(),
            }
        )
        save_db(db)
        return user_id


def list_users(
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_location: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Restituisce tutti gli utenti, con filtri opzionali."""
    if role is not None:
        role = _validate_choice(role, ("admin", "adult", "child"), "role")
    if current_location is not None:
        current_location = _validate_choice(
            current_location,
            ("inside", "outside", "unknown"),
            "current_location",
        )

    with DB_LOCK:
        db = load_db()
        users = db["users"]
        result = []
        for record in users:
            if role is not None and record.get("role") != role:
                continue
            if is_active is not None and bool(record.get("is_active")) != bool(is_active):
                continue
            if current_location is not None and record.get("current_location") != current_location:
                continue
            result.append(
                {
                    "id": record.get("id"),
                    "email": record.get("email"),
                    "username": record.get("username"),
                    "role": record.get("role"),
                    "uuid": record.get("uuid"),
                    "is_active": bool(record.get("is_active")),
                    "last_seen_at": record.get("last_seen_at"),
                    "current_location": record.get("current_location"),
                    "created_at": record.get("created_at"),
                }
            )
        return sorted(result, key=lambda item: item["id"])


def get_user_by_id(user_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un utente per id."""
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["users"], user_id)
        if record is None:
            return None
        return {
            "id": record.get("id"),
            "email": record.get("email"),
            "username": record.get("username"),
            "role": record.get("role"),
            "uuid": record.get("uuid"),
            "is_active": bool(record.get("is_active")),
            "last_seen_at": record.get("last_seen_at"),
            "current_location": record.get("current_location"),
            "created_at": record.get("created_at"),
        }


def get_user_by_username(username: str) -> Optional[Dict[str, Any]]:
    """Recupera un utente per username."""
    with DB_LOCK:
        db = load_db()
        for record in db["users"]:
            if record.get("username") == username:
                return {
                    "id": record.get("id"),
                    "email": record.get("email"),
                    "username": record.get("username"),
                    "role": record.get("role"),
                    "uuid": record.get("uuid"),
                    "is_active": bool(record.get("is_active")),
                    "last_seen_at": record.get("last_seen_at"),
                    "current_location": record.get("current_location"),
                    "created_at": record.get("created_at"),
                }
        return None


def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Recupera un utente per email."""
    email = email.strip().lower()
    with DB_LOCK:
        db = load_db()
        for record in db["users"]:
            if record.get("email") == email:
                return {
                    "id": record.get("id"),
                    "email": record.get("email"),
                    "username": record.get("username"),
                    "role": record.get("role"),
                    "uuid": record.get("uuid"),
                    "is_active": bool(record.get("is_active")),
                    "last_seen_at": record.get("last_seen_at"),
                    "current_location": record.get("current_location"),
                    "created_at": record.get("created_at"),
                }
        return None


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
    """Aggiorna un utente esistente."""
    with DB_LOCK:
        db = load_db()
        users = db["users"]
        record = find_by_id(users, user_id)
        if record is None:
            return False

        if username is not None:
            if not username.strip():
                raise ValueError("username cannot be empty")
            username = username.strip()
            if _unique_exists(users, "username", username, exclude_id=user_id):
                raise ValueError("email or username already exists")
            record["username"] = username

        if email is not None:
            if not email.strip():
                raise ValueError("email cannot be empty")
            email = email.strip().lower()
            if _unique_exists(users, "email", email, exclude_id=user_id):
                raise ValueError("email or username already exists")
            record["email"] = email

        if password is not None:
            if not password:
                raise ValueError("password cannot be empty")
            record["hash_psw"] = generate_password_hash(password)

        if role is not None:
            record["role"] = _validate_choice(role, ("admin", "adult", "child"), "role")

        if uuid_value is not None:
            uuid_value = str(uuid_value).strip()
            if not uuid_value:
                raise ValueError("uuid cannot be empty")
            if _unique_exists(users, "uuid", uuid_value, exclude_id=user_id):
                raise ValueError("uuid already exists")
            record["uuid"] = uuid_value

        if is_active is not None:
            record["is_active"] = bool(is_active)

        if last_seen_at is not None:
            record["last_seen_at"] = last_seen_at

        if current_location is not None:
            record["current_location"] = _validate_choice(
                current_location,
                ("inside", "outside", "unknown"),
                "current_location",
            )

        save_db(db)
        return True


def delete_user(user_id: int) -> bool:
    """Elimina un utente e i record collegati."""
    with DB_LOCK:
        db = load_db()
        users = db["users"]
        if not delete_by_id(users, user_id):
            return False

        # Cascata manuale per le collezioni collegate.
        db["user_devices"] = [row for row in db["user_devices"] if row.get("user_id") != user_id]
        db["logs"] = [row for row in db["logs"] if row.get("user_id") != user_id]
        db["events"] = [row for row in db["events"] if row.get("user_id") != user_id]

        save_db(db)
        return True


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
    """Crea un dispositivo."""
    if not name or not name.strip():
        raise ValueError("name is required")

    current_status = _validate_choice(
        current_status,
        ("inside", "outside", "unknown"),
        "current_status",
        default="inside",
    )

    name = name.strip()
    if rfid_tag is None or not str(rfid_tag).strip():
        rfid_tag = f"RFID-{uuid4().hex[:12]}"
    rfid_tag = str(rfid_tag).strip()

    with DB_LOCK:
        db = load_db()
        devices = db["devices"]

        if _unique_exists(devices, "rfid_tag", rfid_tag):
            raise ValueError("rfid_tag already exists")

        device_id = next_id(db, "devices")
        devices.append(
            {
                "id": device_id,
                "name": name,
                "rfid_tag": rfid_tag,
                "category": category,
                "is_essential": bool(is_essential),
                "alert_rules": to_json_text(alert_rules),
                "current_status": current_status,
                "created_at": _now_iso(),
            }
        )
        save_db(db)
        return device_id


def list_devices(
    category: Optional[str] = None,
    current_status: Optional[str] = None,
    is_essential: Optional[bool] = None,
) -> List[Dict[str, Any]]:
    """Restituisce tutti i dispositivi, con filtri opzionali."""
    if current_status is not None:
        current_status = _validate_choice(
            current_status,
            ("inside", "outside", "unknown"),
            "current_status",
        )

    with DB_LOCK:
        db = load_db()
        result = []
        for record in db["devices"]:
            if category is not None and record.get("category") != category:
                continue
            if current_status is not None and record.get("current_status") != current_status:
                continue
            if is_essential is not None and bool(record.get("is_essential")) != bool(is_essential):
                continue
            result.append(
                {
                    "id": record.get("id"),
                    "name": record.get("name"),
                    "rfid_tag": record.get("rfid_tag"),
                    "category": record.get("category"),
                    "is_essential": bool(record.get("is_essential")),
                    "alert_rules": record.get("alert_rules"),
                    "current_status": record.get("current_status"),
                    "created_at": record.get("created_at"),
                }
            )
        return sorted(result, key=lambda item: item["id"])


def get_device_by_id(device_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un dispositivo per id."""
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["devices"], device_id)
        if record is None:
            return None
        return {
            "id": record.get("id"),
            "name": record.get("name"),
            "rfid_tag": record.get("rfid_tag"),
            "category": record.get("category"),
            "is_essential": bool(record.get("is_essential")),
            "alert_rules": record.get("alert_rules"),
            "current_status": record.get("current_status"),
            "created_at": record.get("created_at"),
        }


def get_device_by_rfid_tag(rfid_tag: str) -> Optional[Dict[str, Any]]:
    """Recupera un dispositivo tramite tag RFID."""
    with DB_LOCK:
        db = load_db()
        for record in db["devices"]:
            if record.get("rfid_tag") == rfid_tag:
                return {
                    "id": record.get("id"),
                    "name": record.get("name"),
                    "rfid_tag": record.get("rfid_tag"),
                    "category": record.get("category"),
                    "is_essential": bool(record.get("is_essential")),
                    "alert_rules": record.get("alert_rules"),
                    "current_status": record.get("current_status"),
                    "created_at": record.get("created_at"),
                }
        return None


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
    with DB_LOCK:
        db = load_db()
        devices = db["devices"]
        record = find_by_id(devices, device_id)
        if record is None:
            return False

        if name is not None:
            if not name.strip():
                raise ValueError("name cannot be empty")
            record["name"] = name.strip()

        if rfid_tag is not None:
            rfid_tag = str(rfid_tag).strip()
            if not rfid_tag:
                raise ValueError("rfid_tag cannot be empty")
            if _unique_exists(devices, "rfid_tag", rfid_tag, exclude_id=device_id):
                raise ValueError("rfid_tag already exists")
            record["rfid_tag"] = rfid_tag

        if category is not None:
            record["category"] = category

        if is_essential is not None:
            record["is_essential"] = bool(is_essential)

        if alert_rules is not None:
            record["alert_rules"] = to_json_text(alert_rules)

        if current_status is not None:
            record["current_status"] = _validate_choice(
                current_status,
                ("inside", "outside", "unknown"),
                "current_status",
            )

        save_db(db)
        return True


def delete_device(device_id: int) -> bool:
    """Elimina un dispositivo e i record collegati."""
    with DB_LOCK:
        db = load_db()
        devices = db["devices"]
        if not delete_by_id(devices, device_id):
            return False

        db["user_devices"] = [row for row in db["user_devices"] if row.get("device_id") != device_id]
        db["logs"] = [row for row in db["logs"] if row.get("device_id") != device_id]

        save_db(db)
        return True


# --------------------------------------------------------------------------------------
# ASSOCIAZIONI USER <-> DEVICE
# --------------------------------------------------------------------------------------
def create_user_device(user_id: int, device_id: int) -> int:
    """Crea un'associazione tra utente e dispositivo."""
    _ensure_user_exists(user_id)
    _ensure_device_exists(device_id)

    with DB_LOCK:
        db = load_db()
        associations = db["user_devices"]

        for record in associations:
            if record.get("user_id") == user_id and record.get("device_id") == device_id:
                return int(record["id"])

        association_id = next_id(db, "user_devices")
        associations.append(
            {
                "id": association_id,
                "user_id": user_id,
                "device_id": device_id,
            }
        )
        save_db(db)
        return association_id


def list_user_devices(
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
) -> List[Dict[str, Any]]:
    """Restituisce le associazioni utente-dispositivo, con filtri opzionali."""
    with DB_LOCK:
        db = load_db()
        result: List[Dict[str, Any]] = []

        for association in db["user_devices"]:
            if user_id is not None and association.get("user_id") != user_id:
                continue
            if device_id is not None and association.get("device_id") != device_id:
                continue

            user = get_user_by_id(int(association["user_id"]))
            device = get_device_by_id(int(association["device_id"]))
            if user is None or device is None:
                continue

            result.append(
                {
                    "association_id": association.get("id"),
                    "user_id": user.get("id"),
                    "username": user.get("username"),
                    "email": user.get("email"),
                    "device_id": device.get("id"),
                    "device_name": device.get("name"),
                    "rfid_tag": device.get("rfid_tag"),
                    "category": device.get("category"),
                    "current_status": device.get("current_status"),
                }
            )

        return sorted(result, key=lambda item: item["association_id"])


def get_user_device(association_id: int) -> Optional[Dict[str, Any]]:
    """Recupera una singola associazione tramite id."""
    with DB_LOCK:
        db = load_db()
        association = find_by_id(db["user_devices"], association_id)
        if association is None:
            return None

        user = get_user_by_id(int(association["user_id"]))
        device = get_device_by_id(int(association["device_id"]))
        if user is None or device is None:
            return None

        return {
            "association_id": association.get("id"),
            "user_id": user.get("id"),
            "username": user.get("username"),
            "email": user.get("email"),
            "device_id": device.get("id"),
            "device_name": device.get("name"),
            "rfid_tag": device.get("rfid_tag"),
            "category": device.get("category"),
            "current_status": device.get("current_status"),
        }


def delete_user_device(association_id: int) -> bool:
    """Elimina un'associazione user-device."""
    with DB_LOCK:
        db = load_db()
        if not delete_by_id(db["user_devices"], association_id):
            return False
        save_db(db)
        return True


# --------------------------------------------------------------------------------------
# LOGS
# --------------------------------------------------------------------------------------
def create_log(
    user_id: int,
    device_id: int,
    action: str,
    created_at: Optional[str] = None,
) -> int:
    """Crea un log ingresso/uscita."""
    _ensure_user_exists(user_id)
    _ensure_device_exists(device_id)

    action = action.strip().upper()
    if action not in ("ENTRATO", "USCITO"):
        raise ValueError("action must be 'ENTRATO' or 'USCITO'")

    with DB_LOCK:
        db = load_db()
        log_id = next_id(db, "logs")
        db["logs"].append(
            {
                "id": log_id,
                "user_id": user_id,
                "device_id": device_id,
                "action": action,
                "created_at": created_at or _now_iso(),
            }
        )
        save_db(db)
        return log_id


def list_logs(
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
    action: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Restituisce i log, con filtri opzionali."""
    if action is not None:
        action = action.strip().upper()
        if action not in ("ENTRATO", "USCITO"):
            raise ValueError("action must be 'ENTRATO' or 'USCITO'")

    with DB_LOCK:
        db = load_db()
        result: List[Dict[str, Any]] = []
        for record in db["logs"]:
            if user_id is not None and record.get("user_id") != user_id:
                continue
            if device_id is not None and record.get("device_id") != device_id:
                continue
            if action is not None and record.get("action") != action:
                continue
            result.append(
                {
                    "id": record.get("id"),
                    "user_id": record.get("user_id"),
                    "device_id": record.get("device_id"),
                    "action": record.get("action"),
                    "created_at": record.get("created_at"),
                }
            )
        return sorted(result, key=lambda item: item["id"])


def get_log_by_id(log_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un log tramite id."""
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["logs"], log_id)
        if record is None:
            return None
        return {
            "id": record.get("id"),
            "user_id": record.get("user_id"),
            "device_id": record.get("device_id"),
            "action": record.get("action"),
            "created_at": record.get("created_at"),
        }


def update_log(
    log_id: int,
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
    action: Optional[str] = None,
    created_at: Optional[str] = None,
) -> bool:
    """Aggiorna un log esistente."""
    with DB_LOCK:
        db = load_db()
        logs = db["logs"]
        record = find_by_id(logs, log_id)
        if record is None:
            return False

        if user_id is not None:
            _ensure_user_exists(user_id)
            record["user_id"] = user_id

        if device_id is not None:
            _ensure_device_exists(device_id)
            record["device_id"] = device_id

        if action is not None:
            action = action.strip().upper()
            if action not in ("ENTRATO", "USCITO"):
                raise ValueError("action must be 'ENTRATO' or 'USCITO'")
            record["action"] = action

        if created_at is not None:
            record["created_at"] = created_at

        save_db(db)
        return True


def delete_log(log_id: int) -> bool:
    """Elimina un log."""
    with DB_LOCK:
        db = load_db()
        if not delete_by_id(db["logs"], log_id):
            return False
        save_db(db)
        return True


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

    with DB_LOCK:
        db = load_db()
        event_id = next_id(db, "events")
        db["events"].append(
            {
                "id": event_id,
                "user_id": user_id,
                "event_type": event_type,
                "direction": direction,
                "detected_objects": to_json_text(detected_objects),
                "detected_users": to_json_text(detected_users),
                "created_at": _now_iso(),
            }
        )
        save_db(db)
        return event_id


def list_events(
    user_id: Optional[int] = None,
    event_type: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Restituisce gli eventi, con filtri opzionali."""
    allowed = ("passage_in", "passage_out", "alert", "system")
    if event_type is not None and event_type not in allowed:
        raise ValueError(f"event_type must be one of {allowed}")

    with DB_LOCK:
        db = load_db()
        result = []
        for record in db["events"]:
            if user_id is not None and record.get("user_id") != user_id:
                continue
            if event_type is not None and record.get("event_type") != event_type:
                continue
            result.append(
                {
                    "id": record.get("id"),
                    "user_id": record.get("user_id"),
                    "event_type": record.get("event_type"),
                    "direction": record.get("direction"),
                    "detected_objects": record.get("detected_objects"),
                    "detected_users": record.get("detected_users"),
                    "created_at": record.get("created_at"),
                }
            )
        return sorted(result, key=lambda item: item["id"])


def get_event_by_id(event_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un evento tramite id."""
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["events"], event_id)
        if record is None:
            return None
        return {
            "id": record.get("id"),
            "user_id": record.get("user_id"),
            "event_type": record.get("event_type"),
            "direction": record.get("direction"),
            "detected_objects": record.get("detected_objects"),
            "detected_users": record.get("detected_users"),
            "created_at": record.get("created_at"),
        }


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
    allowed = ("passage_in", "passage_out", "alert", "system")

    with DB_LOCK:
        db = load_db()
        events = db["events"]
        record = find_by_id(events, event_id)
        if record is None:
            return False

        if user_id is not None:
            _ensure_user_exists(user_id)
            record["user_id"] = user_id

        if event_type is not None:
            if event_type not in allowed:
                raise ValueError(f"event_type must be one of {allowed}")
            record["event_type"] = event_type

        if direction is not None:
            if direction not in ("in", "out"):
                raise ValueError("direction must be 'in' or 'out'")
            record["direction"] = direction

        if detected_objects is not None:
            record["detected_objects"] = to_json_text(detected_objects)

        if detected_users is not None:
            record["detected_users"] = to_json_text(detected_users)

        if created_at is not None:
            record["created_at"] = created_at

        save_db(db)
        return True


def delete_event(event_id: int) -> bool:
    """Elimina un evento."""
    with DB_LOCK:
        db = load_db()
        if not delete_by_id(db["events"], event_id):
            return False
        save_db(db)
        return True
