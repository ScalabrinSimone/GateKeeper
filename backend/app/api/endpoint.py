
"""API FastAPI del progetto.

Questo modulo espone CRUD completi per:
- users
- devices
- user_devices
- logs
- events

Inoltre avvia un thread in background per il lettore RFID, così il
server continua a rispondere alle richieste mentre il reader resta attivo.
"""

from __future__ import annotations

import threading
from typing import Any, List, Optional, Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.db import models
from app.rfid import rfidreader


app = FastAPI(title="Device Access API", version="2.0.0")


# --------------------------------------------------------------------------------------
# Modelli Pydantic
# --------------------------------------------------------------------------------------
class UserCreate(BaseModel):
    """Dati per creare un utente."""
    username: str
    password: str
    email: Optional[str] = None
    role: str = "adult"
    uuid_value: Optional[str] = Field(default=None, alias="uuid")
    is_active: bool = True
    last_seen_at: Optional[str] = None
    current_location: str = "unknown"


class UserUpdate(BaseModel):
    """Dati per aggiornare un utente: tutti i campi sono opzionali."""
    username: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    role: Optional[str] = None
    uuid_value: Optional[str] = Field(default=None, alias="uuid")
    is_active: Optional[bool] = None
    last_seen_at: Optional[str] = None
    current_location: Optional[str] = None


class UserOut(BaseModel):
    id: int
    email: str
    username: str
    role: str
    uuid: Optional[str] = None
    is_active: bool
    last_seen_at: Optional[str] = None
    current_location: str
    created_at: str


class DeviceCreate(BaseModel):
    """Dati per creare un dispositivo."""
    name: str
    rfid_tag: Optional[str] = None
    category: str = "other"
    is_essential: bool = False
    alert_rules: Any = "{}"
    current_status: str = "inside"


class DeviceUpdate(BaseModel):
    """Dati per aggiornare un dispositivo."""
    name: Optional[str] = None
    rfid_tag: Optional[str] = None
    category: Optional[str] = None
    is_essential: Optional[bool] = None
    alert_rules: Optional[Any] = None
    current_status: Optional[str] = None


class DeviceOut(BaseModel):
    id: int
    name: str
    rfid_tag: str
    category: str
    is_essential: bool
    alert_rules: str
    current_status: str
    created_at: str


class AssociationCreate(BaseModel):
    """Associazione utente-dispositivo."""
    user_id: int
    device_id: int


class AssociationOut(BaseModel):
    association_id: int
    user_id: int
    username: str
    email: str
    device_id: int
    device_name: str
    rfid_tag: str
    category: str
    current_status: str


class LogCreate(BaseModel):
    user_id: int
    device_id: int
    action: Literal["ENTRATO", "USCITO"]
    created_at: Optional[str] = None


class LogUpdate(BaseModel):
    user_id: Optional[int] = None
    device_id: Optional[int] = None
    action: Optional[Literal["ENTRATO", "USCITO"]] = None
    created_at: Optional[str] = None


class LogOut(BaseModel):
    id: int
    user_id: int
    device_id: int
    action: str
    created_at: str


class EventCreate(BaseModel):
    user_id: Optional[int] = None
    event_type: Literal["passage_in", "passage_out", "alert", "system"]
    direction: Optional[Literal["in", "out"]] = None
    detected_objects: Any = "[]"
    detected_users: Any = "[]"


class EventUpdate(BaseModel):
    user_id: Optional[int] = None
    event_type: Optional[Literal["passage_in", "passage_out", "alert", "system"]] = None
    direction: Optional[Literal["in", "out"]] = None
    detected_objects: Optional[Any] = None
    detected_users: Optional[Any] = None
    created_at: Optional[str] = None


class EventOut(BaseModel):
    id: int
    user_id: Optional[int] = None
    event_type: str
    direction: Optional[str] = None
    detected_objects: str
    detected_users: str
    created_at: str


# --------------------------------------------------------------------------------------
# Stato globale per il lettore RFID
# --------------------------------------------------------------------------------------
_rfid_stop_event = threading.Event()
_rfid_thread: Optional[threading.Thread] = None
_rfid_seen_tags: set[str] = set()
_rfid_seen_lock = threading.Lock()


def _rfid_tag_callback(tag: str) -> None:
    """Callback eseguita quando il lettore RFID intercetta un tag valido.

    Per rendere il sistema coeso, ogni tag nuovo nel corso della sessione
    viene registrato come evento di sistema nel database.
    """
    with _rfid_seen_lock:
        if tag in _rfid_seen_tags:
            return
        _rfid_seen_tags.add(tag)

    try:
        models.create_event(
            user_id=None,
            event_type="system",
            direction=None,
            detected_objects=[{"rfid_tag": tag, "source": "rfid_reader"}],
            detected_users=[],
        )
        print(f"Evento RFID registrato per il tag: {tag}")
    except Exception as exc:
        print("Impossibile salvare l'evento RFID:", exc)


def _start_rfid_thread() -> None:
    """Avvia il thread del lettore RFID se non è già attivo."""
    global _rfid_thread
    if _rfid_thread is not None and _rfid_thread.is_alive():
        return

    _rfid_stop_event.clear()
    _rfid_thread = threading.Thread(
        target=rfidreader.run_reader,
        kwargs={"stop_event": _rfid_stop_event, "on_tag": _rfid_tag_callback},
        daemon=True,
        name="rfid-reader-thread",
    )
    _rfid_thread.start()
    print("Thread RFID avviato.")


def _stop_rfid_thread() -> None:
    """Ferma il thread RFID in modo ordinato."""
    global _rfid_thread
    _rfid_stop_event.set()
    if _rfid_thread is not None:
        _rfid_thread.join(timeout=5)
        _rfid_thread = None
    print("Thread RFID fermato.")


@app.on_event("startup")
def on_startup() -> None:
    """All'avvio dell'API parte anche il lettore RFID."""
    _start_rfid_thread()


@app.on_event("shutdown")
def on_shutdown() -> None:
    """Alla chiusura del server, il thread RFID viene fermato."""
    _stop_rfid_thread()


@app.get("/")
def home() -> dict[str, str]:
    """Piccolo endpoint di benvenuto e health check."""
    return {"message": "Device Access API attiva"}


# --------------------------------------------------------------------------------------
# USERS
# --------------------------------------------------------------------------------------
@app.post("/users", response_model=UserOut)
def create_user(req: UserCreate):
    """Crea un utente nel database."""
    try:
        user_id = models.create_user(
            req.username,
            req.password,
            email=req.email,
            role=req.role,
            uuid_value=req.uuid_value,
            is_active=req.is_active,
            last_seen_at=req.last_seen_at,
            current_location=req.current_location,
        )
        user = models.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=500, detail="User created but not found")
        return user
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/users", response_model=List[UserOut])
def list_users(
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_location: Optional[str] = None,
):
    """Elenca gli utenti con filtri opzionali."""
    try:
        return models.list_users(role=role, is_active=is_active, current_location=current_location)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/users/{user_id}", response_model=UserOut)
def get_user(user_id: int):
    """Recupera un utente per id."""
    user = models.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@app.get("/users/by-username/{username}", response_model=UserOut)
def get_user_by_username(username: str):
    """Recupera un utente per username."""
    user = models.get_user_by_username(username)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@app.put("/users/{user_id}", response_model=UserOut)
def update_user(user_id: int, req: UserUpdate):
    """Aggiorna un utente esistente."""
    try:
        updated = models.update_user(
            user_id,
            username=req.username,
            email=req.email,
            password=req.password,
            role=req.role,
            uuid_value=req.uuid_value,
            is_active=req.is_active,
            last_seen_at=req.last_seen_at,
            current_location=req.current_location,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="User not found")
        user = models.get_user_by_id(user_id)
        if not user:
            raise HTTPException(status_code=500, detail="User updated but not found")
        return user
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.delete("/users/{user_id}")
def delete_user(user_id: int):
    """Elimina un utente."""
    if not models.delete_user(user_id):
        raise HTTPException(status_code=404, detail="User not found")
    return {"deleted": True, "user_id": user_id}


# --------------------------------------------------------------------------------------
# DEVICES
# --------------------------------------------------------------------------------------
@app.post("/devices", response_model=DeviceOut)
def create_device(req: DeviceCreate):
    """Crea un dispositivo nel database."""
    try:
        device_id = models.create_device(
            req.name,
            rfid_tag=req.rfid_tag,
            category=req.category,
            is_essential=req.is_essential,
            alert_rules=req.alert_rules,
            current_status=req.current_status,
        )
        device = models.get_device_by_id(device_id)
        if not device:
            raise HTTPException(status_code=500, detail="Device created but not found")
        return device
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/devices", response_model=List[DeviceOut])
def list_devices(
    category: Optional[str] = None,
    current_status: Optional[str] = None,
    is_essential: Optional[bool] = None,
):
    """Elenca i dispositivi con filtri opzionali."""
    try:
        return models.list_devices(
            category=category,
            current_status=current_status,
            is_essential=is_essential,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/devices/{device_id}", response_model=DeviceOut)
def get_device(device_id: int):
    """Recupera un dispositivo per id."""
    device = models.get_device_by_id(device_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    return device


@app.get("/devices/by-rfid/{rfid_tag}", response_model=DeviceOut)
def get_device_by_rfid(rfid_tag: str):
    """Recupera un dispositivo tramite tag RFID."""
    device = models.get_device_by_rfid_tag(rfid_tag)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    return device


@app.put("/devices/{device_id}", response_model=DeviceOut)
def update_device(device_id: int, req: DeviceUpdate):
    """Aggiorna un dispositivo esistente."""
    try:
        updated = models.update_device(
            device_id,
            name=req.name,
            rfid_tag=req.rfid_tag,
            category=req.category,
            is_essential=req.is_essential,
            alert_rules=req.alert_rules,
            current_status=req.current_status,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Device not found")
        device = models.get_device_by_id(device_id)
        if not device:
            raise HTTPException(status_code=500, detail="Device updated but not found")
        return device
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.delete("/devices/{device_id}")
def delete_device(device_id: int):
    """Elimina un dispositivo."""
    if not models.delete_device(device_id):
        raise HTTPException(status_code=404, detail="Device not found")
    return {"deleted": True, "device_id": device_id}


# --------------------------------------------------------------------------------------
# ASSOCIAZIONI
# --------------------------------------------------------------------------------------
@app.post("/user-devices", response_model=dict[str, int])
def create_association(req: AssociationCreate):
    """Crea un'associazione utente-dispositivo."""
    try:
        association_id = models.create_user_device(req.user_id, req.device_id)
        return {"association_id": association_id}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/user-devices", response_model=List[AssociationOut])
def list_associations(user_id: Optional[int] = None, device_id: Optional[int] = None):
    """Elenca le associazioni con filtri opzionali."""
    return models.list_user_devices(user_id=user_id, device_id=device_id)


@app.get("/user-devices/{association_id}", response_model=AssociationOut)
def get_association(association_id: int):
    """Recupera una singola associazione."""
    association = models.get_user_device(association_id)
    if not association:
        raise HTTPException(status_code=404, detail="Association not found")
    return association


@app.delete("/user-devices/{association_id}")
def delete_association(association_id: int):
    """Elimina un'associazione."""
    if not models.delete_user_device(association_id):
        raise HTTPException(status_code=404, detail="Association not found")
    return {"deleted": True, "association_id": association_id}


# --------------------------------------------------------------------------------------
# LOGS
# --------------------------------------------------------------------------------------
@app.post("/logs", response_model=LogOut)
def create_log(req: LogCreate):
    """Crea un log ingresso/uscita."""
    try:
        log_id = models.create_log(
            req.user_id,
            req.device_id,
            req.action,
            created_at=req.created_at,
        )
        log = models.get_log_by_id(log_id)
        if not log:
            raise HTTPException(status_code=500, detail="Log created but not found")
        return log
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/logs", response_model=List[LogOut])
def list_logs(
    user_id: Optional[int] = None,
    device_id: Optional[int] = None,
    action: Optional[str] = None,
):
    """Elenca i log con filtri opzionali."""
    try:
        return models.list_logs(user_id=user_id, device_id=device_id, action=action)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/logs/{log_id}", response_model=LogOut)
def get_log(log_id: int):
    """Recupera un log per id."""
    log = models.get_log_by_id(log_id)
    if not log:
        raise HTTPException(status_code=404, detail="Log not found")
    return log


@app.put("/logs/{log_id}", response_model=LogOut)
def update_log(log_id: int, req: LogUpdate):
    """Aggiorna un log esistente."""
    try:
        updated = models.update_log(
            log_id,
            user_id=req.user_id,
            device_id=req.device_id,
            action=req.action,
            created_at=req.created_at,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Log not found")
        log = models.get_log_by_id(log_id)
        if not log:
            raise HTTPException(status_code=500, detail="Log updated but not found")
        return log
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.delete("/logs/{log_id}")
def delete_log(log_id: int):
    """Elimina un log."""
    if not models.delete_log(log_id):
        raise HTTPException(status_code=404, detail="Log not found")
    return {"deleted": True, "log_id": log_id}


# --------------------------------------------------------------------------------------
# EVENTS
# --------------------------------------------------------------------------------------
@app.post("/events", response_model=EventOut)
def create_event(req: EventCreate):
    """Crea un evento generico."""
    try:
        event_id = models.create_event(
            req.user_id,
            req.event_type,
            direction=req.direction,
            detected_objects=req.detected_objects,
            detected_users=req.detected_users,
        )
        event = models.get_event_by_id(event_id)
        if not event:
            raise HTTPException(status_code=500, detail="Event created but not found")
        return event
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/events", response_model=List[EventOut])
def list_events(user_id: Optional[int] = None, event_type: Optional[str] = None):
    """Elenca gli eventi con filtri opzionali."""
    try:
        return models.list_events(user_id=user_id, event_type=event_type)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/events/{event_id}", response_model=EventOut)
def get_event(event_id: int):
    """Recupera un evento per id."""
    event = models.get_event_by_id(event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event


@app.put("/events/{event_id}", response_model=EventOut)
def update_event(event_id: int, req: EventUpdate):
    """Aggiorna un evento esistente."""
    try:
        updated = models.update_event(
            event_id,
            user_id=req.user_id,
            event_type=req.event_type,
            direction=req.direction,
            detected_objects=req.detected_objects,
            detected_users=req.detected_users,
            created_at=req.created_at,
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Event not found")
        event = models.get_event_by_id(event_id)
        if not event:
            raise HTTPException(status_code=500, detail="Event updated but not found")
        return event
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.delete("/events/{event_id}")
def delete_event(event_id: int):
    """Elimina un evento."""
    if not models.delete_event(event_id):
        raise HTTPException(status_code=404, detail="Event not found")
    return {"deleted": True, "event_id": event_id}
