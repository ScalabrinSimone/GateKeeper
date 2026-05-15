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

from fastapi import FastAPI, HTTPException, Header, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.db import models
from app.rfid import rfidreader
from app.security import tokens as gk_tokens
from app.security.mailer import send_mail
from app.services import discovery as gk_discovery


app = FastAPI(title="Device Access API", version="2.0.0")

# CORS aperta: l'app Flutter (anche web/dev) deve poter chiamare l'API da localhost
# e dalla LAN. In produzione domestica resta dietro tunnel; in dev è utile.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


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
    # Permessi granulari (override per ruolo). L'admin ha tutto True.
    permissions: dict[str, bool] = Field(default_factory=dict)
    # Token push registrati dai dispositivi dell'utente (FCM/APNs).
    push_tokens: list[dict[str, Any]] = Field(default_factory=list)


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

    - Memorizza i tag sconosciuti in un buffer in-memory così che l'app
      possa offrire una UX "avvicina il tag" durante la registrazione di un
      nuovo oggetto.
    - Per rendere il sistema coeso, ogni tag nuovo nel corso della sessione
      viene registrato come evento di sistema nel database.
    """
    # Sempre aggiornato il buffer: gestisce internamente i duplicati.
    try:
        models.remember_unknown_tag(tag)
    except Exception as exc:
        print("Impossibile memorizzare tag sconosciuto:", exc)

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
        target=rfidreader.runReader,
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


# ======================================================================================
# AUTH / PAIRING / HUB / INVITES / RECOVERY
# ======================================================================================
class LoginRequest(BaseModel):
    """Login: accetta username o email + password."""
    identifier: str
    password: str


class RegisterAdminRequest(BaseModel):
    """Creazione dell'admin durante il primo pairing."""
    house_name: str
    username: str
    password: str
    email: str
    factory_code: Optional[str] = None


class PairStatus(BaseModel):
    paired: bool
    house_name: Optional[str] = None
    admin_user_id: Optional[int] = None
    paired_at: Optional[str] = None
    api_version: str = "2.0.0"


class HubInfo(BaseModel):
    paired: bool
    house_name: Optional[str] = None
    api_version: str = "2.0.0"
    requires_factory_code: bool = False


class TokenResponse(BaseModel):
    token: str
    user: UserOut


class InviteCreate(BaseModel):
    role: str = "adult"
    suggested_name: Optional[str] = None
    ttl_hours: int = 24 * 7


class InviteOut(BaseModel):
    id: int
    token: str
    role: str
    suggested_name: Optional[str] = None
    created_by: int
    created_at: str
    expires_at: str
    consumed: bool


class InviteAccept(BaseModel):
    token: str
    username: str
    password: str
    email: Optional[str] = None


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


class FactoryResetRequest(BaseModel):
    confirm: bool = False


def _get_current_user(authorization: Optional[str] = Header(default=None)) -> dict:
    """Dependency: estrae l'utente corrente dal token Bearer."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = gk_tokens.decode_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="invalid or expired token")
    user_id = int(payload.get("sub", 0))
    user = models.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=401, detail="user not found")
    return user


def _require_admin(user: dict = Depends(_get_current_user)) -> dict:
    """Dependency: blocca chi non è admin."""
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="admin only")
    return user


# --------------------------------------------------------------------------------------
# HUB / PAIRING (pubblici)
# --------------------------------------------------------------------------------------
@app.get("/hub/info", response_model=HubInfo)
def hub_info():
    """Info pubbliche dell'hub, usate dall'app per capire se va fatto pairing."""
    state = models.get_hub()
    return HubInfo(
        paired=bool(state.get("paired")),
        house_name=state.get("house_name"),
        requires_factory_code=bool(state.get("factory_code")) and not state.get("paired"),
    )


@app.get("/hub/status", response_model=PairStatus)
def hub_status():
    """Stato dettagliato dell'hub (paired/admin/house_name/...)."""
    state = models.get_hub()
    return PairStatus(
        paired=bool(state.get("paired")),
        house_name=state.get("house_name"),
        admin_user_id=state.get("admin_user_id"),
        paired_at=state.get("paired_at"),
    )


@app.post("/hub/pair", response_model=TokenResponse)
def hub_pair(req: RegisterAdminRequest):
    """Primo pairing dell'hub: crea l'admin e marca l'hub come configurato.

    Se è impostato un `factory_code` (dopo un reset di fabbrica), deve
    coincidere con quello passato.
    """
    state = models.get_hub()
    if state.get("paired"):
        raise HTTPException(status_code=409, detail="hub already paired")

    expected_code = state.get("factory_code")
    if expected_code:
        if not req.factory_code or req.factory_code.strip().upper() != str(expected_code).upper():
            raise HTTPException(status_code=403, detail="invalid factory code")

    if not req.house_name.strip():
        raise HTTPException(status_code=400, detail="house_name required")

    try:
        user_id = models.create_user(
            username=req.username,
            password=req.password,
            email=req.email,
            role="admin",
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    from datetime import datetime, timezone
    now_iso = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    models.set_hub({
        "paired": True,
        "house_name": req.house_name.strip(),
        "admin_user_id": user_id,
        "paired_at": now_iso,
        "factory_code": None,
    })

    user = models.get_user_by_id(user_id)
    token = gk_tokens.encode_token({"sub": user_id, "role": "admin"})
    return TokenResponse(token=token, user=user)


@app.post("/hub/factory-reset")
def hub_factory_reset(req: FactoryResetRequest, _admin: dict = Depends(_require_admin)):
    """Reset di fabbrica: svuota i database e disaccoppia l'hub.

    Va richiamato dall'admin via app. Sul Raspberry è possibile anche tramite
    `scripts/factory_reset.py`.
    """
    if not req.confirm:
        raise HTTPException(status_code=400, detail="confirm=true required")
    gk_tokens.reset_secret()
    new_state = models.factory_reset_all()
    return {"reset": True, "factory_code": new_state.get("factory_code")}


# --------------------------------------------------------------------------------------
# AUTH
# --------------------------------------------------------------------------------------
@app.post("/auth/login", response_model=TokenResponse)
def auth_login(req: LoginRequest):
    """Login con username/email + password. Restituisce token + utente."""
    state = models.get_hub()
    if not state.get("paired"):
        raise HTTPException(status_code=409, detail="hub not paired yet")

    user = models.verify_user_password(req.identifier, req.password)
    if not user:
        raise HTTPException(status_code=401, detail="invalid credentials")
    if not user.get("is_active", True):
        raise HTTPException(status_code=403, detail="user disabled")

    token = gk_tokens.encode_token({"sub": user["id"], "role": user.get("role")})
    return TokenResponse(token=token, user=user)


@app.get("/auth/me", response_model=UserOut)
def auth_me(user: dict = Depends(_get_current_user)):
    """Ritorna l'utente del token corrente."""
    return user


@app.post("/auth/logout")
def auth_logout(_user: dict = Depends(_get_current_user)):
    """Logout client-side: il token va eliminato lato app. Qui solo ack."""
    return {"logout": True}


# --------------------------------------------------------------------------------------
# PASSWORD RECOVERY
# --------------------------------------------------------------------------------------
@app.post("/auth/forgot-password")
def auth_forgot_password(req: ForgotPasswordRequest):
    """Avvia recupero password: invia mail (o scrive su outbox.log se manca SMTP)."""
    record = models.create_password_reset(req.email)
    # Risposta sempre uguale per non rivelare se l'email esiste.
    if record is not None:
        try:
            send_mail(
                to=record["email"],
                subject="GateKeeper · Recupero password",
                body=(
                    "Ciao,\n\n"
                    "Hai chiesto di reimpostare la password di GateKeeper.\n"
                    f"Codice di reset: {record['token']}\n"
                    "Apri l'app, vai su 'Reimposta password' e incolla il codice.\n"
                    "Se non sei stato tu, ignora questa email.\n"
                ),
            )
        except Exception as exc:
            print(f"[AUTH] forgot-password mail error: {exc}")
    return {"sent": True}


@app.post("/auth/reset-password")
def auth_reset_password(req: ResetPasswordRequest):
    """Consuma un token di reset e imposta la nuova password."""
    try:
        ok = models.consume_password_reset(req.token, req.new_password)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    if not ok:
        raise HTTPException(status_code=400, detail="invalid or expired token")
    return {"reset": True}


# --------------------------------------------------------------------------------------
# INVITES
# --------------------------------------------------------------------------------------
@app.post("/invites", response_model=InviteOut)
def invite_create(req: InviteCreate, admin: dict = Depends(_require_admin)):
    """Crea un invito (solo admin). Il token può essere condiviso come link."""
    try:
        record = models.create_invite(
            created_by_user_id=admin["id"],
            role=req.role,
            suggested_name=req.suggested_name,
            ttl_hours=req.ttl_hours,
        )
        return record
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@app.get("/invites", response_model=List[InviteOut])
def invite_list(active_only: bool = True, _admin: dict = Depends(_require_admin)):
    """Elenca gli inviti (solo admin)."""
    return models.list_invites(active_only=active_only)


@app.get("/invites/by-token/{token}", response_model=InviteOut)
def invite_get(token: str):
    """Recupera info di un invito (pubblico, serve all'app per mostrare il form)."""
    record = models.get_invite_by_token(token)
    if not record:
        raise HTTPException(status_code=404, detail="invite not found")
    if record.get("consumed"):
        raise HTTPException(status_code=410, detail="invite already used")
    return record


@app.post("/invites/accept", response_model=TokenResponse)
def invite_accept(req: InviteAccept):
    """Accetta un invito e crea il nuovo membro. Restituisce token utente."""
    try:
        user = models.consume_invite(
            token=req.token,
            username=req.username,
            password=req.password,
            email=req.email,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    token = gk_tokens.encode_token({"sub": user["id"], "role": user.get("role")})
    return TokenResponse(token=token, user=user)


@app.delete("/invites/{invite_id}")
def invite_delete(invite_id: int, _admin: dict = Depends(_require_admin)):
    """Revoca un invito non consumato (solo admin)."""
    ok = models.revoke_invite(invite_id)
    if not ok:
        raise HTTPException(status_code=404, detail="invite not found")
    return {"deleted": True}


# --------------------------------------------------------------------------------------
# PERMISSIONS (gestiti dall'admin sui membri non-admin)
# --------------------------------------------------------------------------------------
class PermissionsUpdate(BaseModel):
    """Patch dei permessi granulari di un utente."""
    permissions: dict[str, bool]


@app.put("/users/{user_id}/permissions", response_model=UserOut)
def update_user_permissions_endpoint(
    user_id: int,
    req: PermissionsUpdate,
    _admin: dict = Depends(_require_admin),
):
    """Aggiorna i permessi granulari di un membro. Solo admin."""
    ok = models.update_user_permissions(user_id, req.permissions)
    if not ok:
        raise HTTPException(status_code=404, detail="user not found")
    user = models.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=500, detail="user updated but not found")
    return user


# --------------------------------------------------------------------------------------
# RFID SCAN (per registrazione tag)
# --------------------------------------------------------------------------------------
class ScannedTagOut(BaseModel):
    tag: str
    seen_at: str


def _require_devices_perm(user: dict = Depends(_get_current_user)) -> dict:
    """Permette accesso a chi ha can_manage_devices (o è admin)."""
    if user.get("role") == "admin":
        return user
    perms = user.get("permissions") or {}
    if not perms.get("can_manage_devices"):
        raise HTTPException(status_code=403, detail="permission denied: can_manage_devices")
    return user


@app.get("/rfid/scan/latest", response_model=Optional[ScannedTagOut])
def rfid_scan_latest(_user: dict = Depends(_require_devices_perm)):
    """Ritorna l'ultimo tag RFID sconosciuto rilevato (o null)."""
    latest = models.latest_unknown_tag()
    return latest


@app.get("/rfid/scan", response_model=List[ScannedTagOut])
def rfid_scan_list(_user: dict = Depends(_require_devices_perm)):
    """Lista degli ultimi tag sconosciuti rilevati."""
    return models.list_unknown_tags()


@app.delete("/rfid/scan/{tag}")
def rfid_scan_consume(tag: str, _user: dict = Depends(_require_devices_perm)):
    """Rimuove un tag dal buffer (lo abbiamo appena associato a un device)."""
    models.consume_unknown_tag(tag)
    return {"consumed": True, "tag": tag}


# --------------------------------------------------------------------------------------
# PUSH TOKENS
# --------------------------------------------------------------------------------------
class PushTokenRegister(BaseModel):
    """Registrazione di un token push (FCM/APNs)."""
    token: str
    platform: Optional[str] = "unknown"


@app.post("/users/me/push-token")
def register_push_token(
    req: PushTokenRegister,
    user: dict = Depends(_get_current_user),
):
    """Registra un push token per l'utente loggato.

    Il token va ottenuto lato app dal SDK FCM/APNs ed inviato qui all'avvio
    e ad ogni rotazione. La consegna remota effettiva delle notifiche viene
    poi fatta dal servizio di delivery (vedi `docs/backend.md`).
    """
    try:
        models.add_push_token(user["id"], req.token, platform=req.platform or "unknown")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return {"registered": True}


@app.delete("/users/me/push-token")
def unregister_push_token(
    token: str,
    user: dict = Depends(_get_current_user),
):
    """Rimuove un push token (es. logout di quel dispositivo)."""
    ok = models.remove_push_token(user["id"], token)
    return {"removed": ok}


# --------------------------------------------------------------------------------------
# HUB DISCOVERY THREAD (avvio insieme al server)
# --------------------------------------------------------------------------------------
_discovery_stop_event = threading.Event()
_discovery_thread: Optional[threading.Thread] = None


def _start_discovery_thread(api_port: int = 8000) -> None:
    """Avvia il listener di discovery in background."""
    global _discovery_thread
    if _discovery_thread is not None and _discovery_thread.is_alive():
        return
    _discovery_stop_event.clear()

    def _runner() -> None:
        gk_discovery.run_discovery_listener(
            api_port=api_port,
            get_hub_info=lambda: models.get_hub(),
            stop_event=_discovery_stop_event,
        )

    _discovery_thread = threading.Thread(
        target=_runner,
        daemon=True,
        name="discovery-listener-thread",
    )
    _discovery_thread.start()
    print("Thread discovery avviato.")


def _stop_discovery_thread() -> None:
    """Ferma il listener di discovery."""
    global _discovery_thread
    _discovery_stop_event.set()
    if _discovery_thread is not None:
        _discovery_thread.join(timeout=3)
        _discovery_thread = None
    print("Thread discovery fermato.")


@app.on_event("startup")
def on_startup_discovery() -> None:
    """Avvia il discovery listener allo startup (porta API di default 8000)."""
    import os
    api_port = int(os.environ.get("GK_API_PORT", "8000"))
    _start_discovery_thread(api_port=api_port)


@app.on_event("shutdown")
def on_shutdown_discovery() -> None:
    _stop_discovery_thread()
