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

from werkzeug.security import generate_password_hash, check_password_hash

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


# Permessi granulari assegnabili ai membri non-admin.
# L'admin ha tutto implicitamente; per gli altri i default dipendono dal ruolo
# e possono essere modificati in app.
PERMISSION_KEYS: tuple[str, ...] = (
    "can_manage_devices",
    "can_manage_users",
    "can_view_events",
    "can_manage_invites",
    "can_acknowledge_alerts",
    "can_configure_hub",
)


def _default_permissions_for_role(role: str) -> Dict[str, bool]:
    """Permessi di default in base al ruolo iniziale dell'utente."""
    if role == "admin":
        return {key: True for key in PERMISSION_KEYS}
    if role == "adult":
        return {
            "can_manage_devices": False,
            "can_manage_users": False,
            "can_view_events": True,
            "can_manage_invites": False,
            "can_acknowledge_alerts": True,
            "can_configure_hub": False,
        }
    # child
    return {key: False for key in PERMISSION_KEYS}


def _normalize_permissions(
    permissions: Optional[Dict[str, Any]],
    role: str,
) -> Dict[str, bool]:
    """Applica i default del ruolo e accetta solo le chiavi note."""
    base = _default_permissions_for_role(role)
    if not permissions:
        return base
    for key, value in permissions.items():
        if key in PERMISSION_KEYS:
            base[key] = bool(value)
    return base


def _user_public(record: Dict[str, Any]) -> Dict[str, Any]:
    """Proiezione 'safe' di un record utente (niente password hash)."""
    role = record.get("role", "adult")
    permissions = _normalize_permissions(record.get("permissions"), role)
    return {
        "id": record.get("id"),
        "email": record.get("email"),
        "username": record.get("username"),
        "role": role,
        "uuid": record.get("uuid"),
        "is_active": bool(record.get("is_active")),
        "last_seen_at": record.get("last_seen_at"),
        "current_location": record.get("current_location"),
        "created_at": record.get("created_at"),
        "permissions": permissions,
        "push_tokens": list(record.get("push_tokens") or []),
    }


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
    permissions: Optional[Dict[str, Any]] = None,
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
    perms = _normalize_permissions(permissions, role)

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
                "permissions": perms,
                "push_tokens": [],
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
            result.append(_user_public(record))
        return sorted(result, key=lambda item: item["id"])


def get_user_by_id(user_id: int) -> Optional[Dict[str, Any]]:
    """Recupera un utente per id."""
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["users"], user_id)
        return _user_public(record) if record is not None else None


def get_user_by_username(username: str) -> Optional[Dict[str, Any]]:
    """Recupera un utente per username."""
    with DB_LOCK:
        db = load_db()
        for record in db["users"]:
            if record.get("username") == username:
                return _user_public(record)
        return None


def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Recupera un utente per email."""
    email = email.strip().lower()
    with DB_LOCK:
        db = load_db()
        for record in db["users"]:
            if record.get("email") == email:
                return _user_public(record)
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


# --------------------------------------------------------------------------------------
# AUTH HELPERS
# --------------------------------------------------------------------------------------
def verify_user_password(identifier: str, password: str) -> Optional[Dict[str, Any]]:
    """Verifica username/email + password. Ritorna l'utente se ok, altrimenti None."""
    from werkzeug.security import check_password_hash

    if not identifier or not password:
        return None

    identifier_norm = identifier.strip().lower()
    with DB_LOCK:
        db = load_db()
        for record in db["users"]:
            if (
                str(record.get("username", "")).lower() == identifier_norm
                or str(record.get("email", "")).lower() == identifier_norm
            ):
                try:
                    if check_password_hash(record.get("hash_psw", ""), password):
                        return _user_public(record)
                except Exception:
                    return None
                return None
    return None


def update_user_permissions(
    user_id: int,
    permissions: Dict[str, Any],
) -> bool:
    """Aggiorna i permessi granulari di un utente.

    L'admin non può perdere i propri permessi: in tal caso vengono forzati
    a tutto True. Tutte le chiavi non in PERMISSION_KEYS sono ignorate.
    """
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["users"], user_id)
        if record is None:
            return False
        role = record.get("role", "adult")
        normalized = _normalize_permissions(permissions, role)
        if role == "admin":
            normalized = {key: True for key in PERMISSION_KEYS}
        record["permissions"] = normalized
        save_db(db)
        return True


# --------------------------------------------------------------------------------------
# PUSH TOKENS (FCM/APNs)
# --------------------------------------------------------------------------------------
def add_push_token(user_id: int, token: str, platform: str = "unknown") -> bool:
    """Aggiunge (se assente) un token push di un dispositivo dell'utente."""
    token = (token or "").strip()
    if not token:
        raise ValueError("push token is required")
    if platform not in ("android", "ios", "web", "desktop", "unknown"):
        platform = "unknown"

    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["users"], user_id)
        if record is None:
            return False
        tokens = list(record.get("push_tokens") or [])
        tokens = [t for t in tokens if isinstance(t, dict) and t.get("token") != token]
        tokens.append({"token": token, "platform": platform, "registered_at": _now_iso()})
        record["push_tokens"] = tokens
        save_db(db)
        return True


def remove_push_token(user_id: int, token: str) -> bool:
    """Rimuove un token push (es. logout di un dispositivo)."""
    token = (token or "").strip()
    if not token:
        return False
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["users"], user_id)
        if record is None:
            return False
        tokens = list(record.get("push_tokens") or [])
        new_tokens = [t for t in tokens if not (isinstance(t, dict) and t.get("token") == token)]
        record["push_tokens"] = new_tokens
        save_db(db)
        return True


# --------------------------------------------------------------------------------------
# RFID UNKNOWN TAGS (buffer per la fase di registrazione)
# --------------------------------------------------------------------------------------
import threading as _threading
from collections import deque as _deque

_UNKNOWN_TAGS_LOCK = _threading.Lock()
_UNKNOWN_TAGS: "_deque[Dict[str, Any]]" = _deque(maxlen=20)


def remember_unknown_tag(tag: str) -> None:
    """Memorizza un tag RFID rilevato che non è ancora associato a un device.

    Viene popolato dal callback del lettore RFID. L'app, durante la procedura
    di registrazione di un nuovo oggetto, fa polling su `latest_unknown_tag`
    per pre-compilare automaticamente il campo `rfid_tag`.
    """
    tag = (tag or "").strip()
    if not tag:
        return
    with DB_LOCK:
        db = load_db()
        for record in db.get("devices", []):
            if record.get("rfid_tag") == tag:
                return  # tag già assegnato, non interessante
    with _UNKNOWN_TAGS_LOCK:
        for entry in _UNKNOWN_TAGS:
            if entry.get("tag") == tag:
                entry["seen_at"] = _now_iso()
                return
        _UNKNOWN_TAGS.append({"tag": tag, "seen_at": _now_iso()})


def latest_unknown_tag() -> Optional[Dict[str, Any]]:
    """Restituisce l'ultimo tag sconosciuto rilevato (o None)."""
    with _UNKNOWN_TAGS_LOCK:
        if not _UNKNOWN_TAGS:
            return None
        return dict(_UNKNOWN_TAGS[-1])


def list_unknown_tags() -> List[Dict[str, Any]]:
    """Tutti i tag sconosciuti recenti (più recenti per ultimi)."""
    with _UNKNOWN_TAGS_LOCK:
        return [dict(entry) for entry in _UNKNOWN_TAGS]


def consume_unknown_tag(tag: str) -> bool:
    """Rimuove un tag sconosciuto dal buffer (lo abbiamo appena assegnato)."""
    tag = (tag or "").strip()
    if not tag:
        return False
    with _UNKNOWN_TAGS_LOCK:
        for entry in list(_UNKNOWN_TAGS):
            if entry.get("tag") == tag:
                _UNKNOWN_TAGS.remove(entry)
                return True
    return False


# --------------------------------------------------------------------------------------
# INVITES (link per invitare un nuovo membro)
# --------------------------------------------------------------------------------------
def create_invite(
    created_by_user_id: int,
    role: str = "adult",
    suggested_name: Optional[str] = None,
    ttl_hours: int = 24 * 7,
) -> Dict[str, Any]:
    """Genera un invito monouso a tempo. Restituisce l'invito con il token."""
    from secrets import token_urlsafe
    from datetime import timedelta

    role = _validate_choice(role, ("admin", "adult", "child"), "role", default="adult")
    _ensure_user_exists(created_by_user_id)

    token = token_urlsafe(16)
    expires = datetime.now(timezone.utc) + timedelta(hours=max(1, int(ttl_hours)))

    with DB_LOCK:
        db = load_db()
        invite_id = next_id(db, "invites")
        record = {
            "id": invite_id,
            "token": token,
            "role": role,
            "suggested_name": suggested_name,
            "created_by": created_by_user_id,
            "created_at": _now_iso(),
            "expires_at": expires.replace(microsecond=0).isoformat(),
            "consumed": False,
            "consumed_by": None,
            "consumed_at": None,
        }
        db["invites"].append(record)
        save_db(db)
        return record


def list_invites(active_only: bool = True) -> List[Dict[str, Any]]:
    """Elenca gli inviti generati. Se active_only, esclude i consumati/scaduti."""
    now = datetime.now(timezone.utc)
    with DB_LOCK:
        db = load_db()
        out: List[Dict[str, Any]] = []
        for record in db.get("invites", []):
            if active_only:
                if record.get("consumed"):
                    continue
                try:
                    if datetime.fromisoformat(record["expires_at"]) < now:
                        continue
                except Exception:
                    continue
            out.append(dict(record))
        return sorted(out, key=lambda item: item["id"], reverse=True)


def get_invite_by_token(token: str) -> Optional[Dict[str, Any]]:
    """Recupera un invito tramite token. Non lo consuma."""
    with DB_LOCK:
        db = load_db()
        for record in db.get("invites", []):
            if record.get("token") == token:
                return dict(record)
    return None


def consume_invite(
    token: str,
    username: str,
    password: str,
    email: Optional[str] = None,
) -> Dict[str, Any]:
    """Consuma un invito: crea il nuovo utente con il ruolo previsto."""
    if not username or not password:
        raise ValueError("username e password sono obbligatori")

    with DB_LOCK:
        db = load_db()
        invite_record = None
        for record in db.get("invites", []):
            if record.get("token") == token:
                invite_record = record
                break

        if invite_record is None:
            raise ValueError("invito non trovato")
        if invite_record.get("consumed"):
            raise ValueError("invito già consumato")
        try:
            expires = datetime.fromisoformat(invite_record["expires_at"])
        except Exception:
            raise ValueError("invito non valido")
        if expires < datetime.now(timezone.utc):
            raise ValueError("invito scaduto")

        role = invite_record.get("role", "adult")

    # Creazione utente (usa il lock internamente).
    user_id = create_user(
        username=username,
        password=password,
        email=email,
        role=role,
    )

    with DB_LOCK:
        db = load_db()
        for record in db.get("invites", []):
            if record.get("token") == token:
                record["consumed"] = True
                record["consumed_by"] = user_id
                record["consumed_at"] = _now_iso()
                break
        save_db(db)
        user = get_user_by_id(user_id)
        return user or {"id": user_id}


def revoke_invite(invite_id: int) -> bool:
    """Cancella un invito non ancora consumato."""
    with DB_LOCK:
        db = load_db()
        return delete_by_id(db.get("invites", []), invite_id) and (save_db(db) or True)


# --------------------------------------------------------------------------------------
# PASSWORD RESET
# --------------------------------------------------------------------------------------
def create_password_reset(email: str, ttl_minutes: int = 30) -> Optional[Dict[str, Any]]:
    """Crea un token di reset password. Restituisce None se l'email non esiste."""
    from secrets import token_urlsafe
    from datetime import timedelta

    user = get_user_by_email(email)
    if not user:
        return None

    token = token_urlsafe(20)
    expires = datetime.now(timezone.utc) + timedelta(minutes=max(5, int(ttl_minutes)))

    with DB_LOCK:
        db = load_db()
        reset_id = next_id(db, "password_resets")
        record = {
            "id": reset_id,
            "user_id": user["id"],
            "email": user["email"],
            "token": token,
            "created_at": _now_iso(),
            "expires_at": expires.replace(microsecond=0).isoformat(),
            "used": False,
        }
        db["password_resets"].append(record)
        save_db(db)
        return record


def consume_password_reset(token: str, new_password: str) -> bool:
    """Usa un token di reset per impostare una nuova password."""
    if not new_password or len(new_password) < 6:
        raise ValueError("password troppo corta (min. 6 caratteri)")

    with DB_LOCK:
        db = load_db()
        target = None
        for record in db.get("password_resets", []):
            if record.get("token") == token:
                target = record
                break
        if target is None:
            return False
        if target.get("used"):
            return False
        try:
            expires = datetime.fromisoformat(target["expires_at"])
        except Exception:
            return False
        if expires < datetime.now(timezone.utc):
            return False

        user_id = int(target["user_id"])
        target["used"] = True
        target["used_at"] = _now_iso()
        save_db(db)

    # Aggiornamento password fuori dal blocco precedente per riusare update_user.
    return update_user(user_id, password=new_password)


# --------------------------------------------------------------------------------------
# HUB STATE (singleton meta)
# --------------------------------------------------------------------------------------
def get_hub() -> Dict[str, Any]:
    """Stato dell'hub (paired/admin/house_name/factory_code)."""
    from .storage import get_hub_state
    return get_hub_state()


def set_hub(updates: Dict[str, Any]) -> Dict[str, Any]:
    """Aggiorna lo stato dell'hub."""
    from .storage import set_hub_state
    return set_hub_state(updates)


def factory_reset_all() -> Dict[str, Any]:
    """Svuota tutto e rigenera un factory code per il prossimo pairing."""
    from secrets import token_hex
    from .storage import factory_reset as storage_reset
    new_code = token_hex(3).upper()  # es. "9F2A1C"
    return storage_reset(factory_code=new_code)
