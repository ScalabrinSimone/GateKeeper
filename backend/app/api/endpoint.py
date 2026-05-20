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
    # Verifica email (None = campo non presente, considerato verificato).
    email_verified: Optional[bool] = None


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


def _rfid_tag_callback(tag: str) -> None:
    """Callback eseguita quando il lettore RFID intercetta un tag valido.

    Delega all'event engine che:
    - Memorizza i tag sconosciuti nel buffer (per la UX di registrazione).
    - Se il tag è associato a un device, genera un evento passage_in/out
      correlando con i telefoni BLE nelle vicinanze.
    - Invia notifiche se necessario.
    """
    try:
        from app.services.event_engine import rfid_event_callback
        rfid_event_callback(tag)
    except Exception as exc:
        print(f"[RFID] Errore event engine callback: {exc}")
        #Fallback: memorizza comunque il tag.
        try:
            models.remember_unknown_tag(tag)
        except Exception:
            pass


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


# Supervisor che attiva/disattiva i sensori (RFID + BLE) in base allo stato
# dell'hub. Finché l'hub non è "paired", i sensori restano spenti: l'hub si
# comporta come un prodotto consumer che attiva l'hardware solo dopo che
# l'amministratore ha completato la configurazione iniziale dall'app.
_sensors_supervisor_stop = threading.Event()
_sensors_supervisor_thread: Optional[threading.Thread] = None
_ble_runtime_started = False
_ble_runtime_stop_event: Optional[threading.Event] = None


def _start_ble_thread() -> None:
    """Best-effort: avvia lo scanner BLE in un thread daemon."""
    global _ble_runtime_started, _ble_runtime_stop_event
    if _ble_runtime_started:
        return
    try:
        from app.ble import blescanner
    except Exception as exc:
        print(f"[BLE] Modulo non disponibile, skip: {exc}")
        return
    _ble_runtime_stop_event = threading.Event()
    threading.Thread(
        target=blescanner.runScanner,
        kwargs={"stopEvent": _ble_runtime_stop_event},
        daemon=True,
        name="ble-scanner-thread",
    ).start()
    _ble_runtime_started = True
    print("Thread BLE avviato (post-pairing).")


def _stop_ble_thread() -> None:
    global _ble_runtime_started, _ble_runtime_stop_event
    if _ble_runtime_stop_event is not None:
        _ble_runtime_stop_event.set()
    _ble_runtime_started = False


def _sensors_supervisor_loop() -> None:
    """Loop che adatta lo stato dei thread sensori a quello di pairing."""
    while not _sensors_supervisor_stop.is_set():
        try:
            paired = bool(models.get_hub().get("paired"))
        except Exception:
            paired = False

        if paired:
            _start_rfid_thread()
            _start_ble_thread()
        else:
            _stop_rfid_thread()
            _stop_ble_thread()

        if _sensors_supervisor_stop.wait(2.0):
            break


@app.on_event("startup")
def on_startup() -> None:
    """All'avvio dell'API verifico lo stato hub.

    - Se l'hub è già pairato, accendo subito sensori RFID/BLE.
    - Se non è pairato, NON faccio partire l'hardware: aspetto che
      l'amministratore completi il setup dall'app.
    Il supervisor monitora poi il flag `paired` per attivare/disattivare
    i sensori in tempo reale (es. dopo pairing o factory reset).
    """
    #Avvia l'event engine (carica mappa BLE->utente).
    try:
        from app.services.event_engine import start_engine
        start_engine()
    except Exception as exc:
        print(f"[STARTUP] Errore avvio event engine: {exc}")

    global _sensors_supervisor_thread
    _sensors_supervisor_stop.clear()
    _sensors_supervisor_thread = threading.Thread(
        target=_sensors_supervisor_loop,
        daemon=True,
        name="sensors-supervisor-thread",
    )
    _sensors_supervisor_thread.start()


@app.on_event("shutdown")
def on_shutdown() -> None:
    """Alla chiusura del server, ferma supervisor + sensori."""
    _sensors_supervisor_stop.set()
    _stop_rfid_thread()
    _stop_ble_thread()


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


class HubQr(BaseModel):
    """Payload "QR-friendly" che l'hub espone finché non è accoppiato.

    L'app può:
    - leggerlo direttamente (`GET /hub/qr`) dopo aver scansionato un URL
      manuale, oppure
    - scansionare il QR mostrato dal terminale del Raspberry: il JSON
      contiene gli stessi campi.
    """
    v: int = 1
    kind: str = "gatekeeper_pair"
    base_url: Optional[str] = None
    factory_code: Optional[str] = None
    house_name: Optional[str] = None
    paired: bool = False


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


class SendEmailCodeRequest(BaseModel):
    """Richiesta di invio codice di verifica email."""
    email: str


class VerifyEmailRequest(BaseModel):
    """Verifica del codice email."""
    code: str


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
def _ensure_factory_code_if_needed() -> Optional[str]:
    """Garantisce che, se l'hub non è pairato, esista sempre un factory_code.

    Così la prima volta che l'app contatta l'hub non-pairato può ricevere
    direttamente un codice valido sia da `/hub/info` (flag boolean) sia
    da `/hub/qr` (payload completo).
    """
    state = models.get_hub() or {}
    if state.get("paired"):
        return None
    code = state.get("factory_code")
    if code:
        return str(code)
    from secrets import token_hex
    new_code = token_hex(3).upper()
    models.set_hub({"factory_code": new_code})
    return new_code


@app.get("/hub/info", response_model=HubInfo)
def hub_info(request: Request):
    """Info pubbliche dell'hub, usate dall'app per capire se va fatto pairing."""
    state = models.get_hub() or {}
    if not state.get("paired"):
        _ensure_factory_code_if_needed()
        state = models.get_hub() or {}
    return HubInfo(
        paired=bool(state.get("paired")),
        house_name=state.get("house_name"),
        requires_factory_code=bool(state.get("factory_code")) and not state.get("paired"),
    )


@app.get("/hub/qr", response_model=HubQr)
def hub_qr(request: Request):
    """Payload da incorporare in un QR di pairing.

    Restituisce sempre la base URL "esterna" (ricavata dall'header Host),
    in modo che il QR funzioni anche quando il backend è raggiungibile su
    nomi diversi (LAN, mDNS, tunnel).
    """
    state = models.get_hub() or {}
    code = None
    if not state.get("paired"):
        code = _ensure_factory_code_if_needed()
        state = models.get_hub() or {}

    # Ricostruzione URL base a partire dalla request originale.
    scheme = request.url.scheme or "http"
    host = request.headers.get("host") or f"{request.url.hostname}:{request.url.port or 8000}"
    base_url = f"{scheme}://{host}".rstrip("/")

    return HubQr(
        v=1,
        kind="gatekeeper_pair",
        base_url=base_url,
        factory_code=code if not state.get("paired") else None,
        house_name=state.get("house_name"),
        paired=bool(state.get("paired")),
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
    """Reset di fabbrica: svuota i database, disaccoppia l'hub e riavvia il processo.

    Va richiamato dall'admin via app. Sul Raspberry è possibile anche tramite
    `scripts/factory_reset.py`.

    Dopo il reset, il processo si riavvia automaticamente tramite os.execv
    senza bisogno di intervento umano.
    """
    import os
    import sys
    import threading

    if not req.confirm:
        raise HTTPException(status_code=400, detail="confirm=true required")
    gk_tokens.reset_secret()
    new_state = models.factory_reset_all()

    #Riavvio automatico del processo dopo 1.5 secondi (tempo per rispondere al client).
    def _restart_process() -> None:
        import time as _time
        _time.sleep(1.5)
        try:
            os.execv(sys.executable, [sys.executable] + sys.argv)
        except Exception as exc:
            print(f"[FACTORY-RESET] Errore riavvio processo: {exc}")

    restart_thread = threading.Thread(target=_restart_process, daemon=True, name="restart-thread")
    restart_thread.start()

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
        print(f"[RESET-PWD] Token reset per {record['email']}: {record['token']}")
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
# EMAIL VERIFICATION
# --------------------------------------------------------------------------------------
@app.post("/auth/send-email-code")
def auth_send_email_code(req: SendEmailCodeRequest, user: dict = Depends(_get_current_user)):
    """Invia un codice di verifica a 6 cifre all'email dell'utente autenticato.

    L'email nel body deve corrispondere a quella dell'account (o essere vuota
    per usare quella già registrata). Risponde sempre con {"sent": true} per
    non rivelare se l'email esiste.
    """
    # Usa l'email dell'account se il client non ne passa una diversa.
    target_email = req.email.strip().lower() if req.email.strip() else user.get("email", "")
    if target_email and target_email != user.get("email", "").lower():
        raise HTTPException(status_code=400, detail="email does not match account")

    record = models.create_email_verification(user["id"])
    # Stampa sempre il codice nel terminale (utile in locale senza SMTP).
    print(f"[EMAIL-CODE] Codice per {user['email']}: {record['code']}")
    try:
        send_mail(
            to=user["email"],
            subject="GateKeeper · Codice di verifica",
            body=(
                "Ciao,\n\n"
                "Il tuo codice di verifica GateKeeper è:\n\n"
                f"    {record['code']}\n\n"
                "Il codice è valido per 15 minuti.\n"
                "Se non hai richiesto la verifica, ignora questa email.\n"
            ),
        )
    except Exception as exc:
        print(f"[AUTH] send-email-code mail error: {exc}")
    return {"sent": True}


@app.post("/auth/verify-email")
def auth_verify_email(req: VerifyEmailRequest, user: dict = Depends(_get_current_user)):
    """Verifica il codice email e marca l'account come verificato."""
    ok = models.consume_email_verification(user["id"], req.code.strip())
    if not ok:
        raise HTTPException(status_code=400, detail="invalid or expired code")
    return {"verified": True}


class PatchMeRequest(BaseModel):
    """Aggiornamento parziale del profilo dell'utente autenticato."""
    username: Optional[str] = None
    email: Optional[str] = None
    current_password: Optional[str] = None  # richiesta per cambio password
    new_password: Optional[str] = None


# --------------------------------------------------------------------------------------
# PATCH OWN PROFILE
# --------------------------------------------------------------------------------------
@app.patch("/auth/me", response_model=UserOut)
def auth_patch_me(req: PatchMeRequest, user: dict = Depends(_get_current_user)):
    """Aggiorna username, email e/o password dell'utente autenticato.

    - Per cambiare la password è obbligatorio fornire `current_password`.
    - Se si cambia l'email, `email_verified` viene resettato a False e viene
      inviato automaticamente un nuovo codice di verifica.
    """
    from werkzeug.security import check_password_hash

    user_id = user["id"]
    email_changed = False

    # Validazione password corrente se si vuole cambiare la password.
    if req.new_password is not None:
        if not req.current_password:
            raise HTTPException(status_code=400, detail="current_password required to change password")
        if not check_password_hash(user.get("hash_psw", ""), req.current_password):
            raise HTTPException(status_code=403, detail="current password is incorrect")
        if len(req.new_password) < 6:
            raise HTTPException(status_code=400, detail="new password must be at least 6 characters")

    # Rileva cambio email.
    if req.email is not None and req.email.strip().lower() != user.get("email", "").lower():
        email_changed = True

    try:
        ok = models.update_user(
            user_id,
            username=req.username,
            email=req.email,
            password=req.new_password,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    if not ok:
        raise HTTPException(status_code=404, detail="user not found")

    # Se l'email è cambiata: resetta email_verified e invia nuovo codice.
    if email_changed:
        with models.DB_LOCK:
            db = models.load_db()
            for u in db["users"]:
                if u["id"] == user_id:
                    u["email_verified"] = False
                    break
            models.save_db(db)
        updated_user = models.get_user_by_id(user_id)
        record = models.create_email_verification(user_id)
        print(f"[EMAIL-CODE] Codice verifica nuova email per {updated_user['email']}: {record['code']}")
        try:
            send_mail(
                to=updated_user["email"],
                subject="GateKeeper · Verifica nuova email",
                body=(
                    "Ciao,\n\n"
                    "Hai cambiato l'email del tuo account GateKeeper.\n"
                    "Il tuo codice di verifica è:\n\n"
                    f"    {record['code']}\n\n"
                    "Il codice è valido per 15 minuti.\n"
                    "Se non sei stato tu, contatta l'amministratore.\n"
                ),
            )
        except Exception as exc:
            print(f"[AUTH] patch-me email-code mail error: {exc}")

    updated = models.get_user_by_id(user_id)
    return updated


# --------------------------------------------------------------------------------------
# DELETE OWN ACCOUNT (leave home)
# --------------------------------------------------------------------------------------
@app.delete("/auth/me")
def auth_delete_me(user: dict = Depends(_get_current_user)):
    """L'utente elimina il proprio account ('lascia la casa').

    Se l'utente è l'unico admin rimasto, viene eseguito un factory reset
    completo dell'hub (tutti i dati vengono cancellati).
    """
    user_id = user["id"]
    is_admin = user.get("role") == "admin"

    if is_admin:
        remaining_admins = models.count_admins()
        if remaining_admins <= 1:
            # Ultimo admin: factory reset completo.
            gk_tokens.reset_secret()
            new_state = models.factory_reset_all()
            return {
                "deleted": True,
                "factory_reset": True,
                "factory_code": new_state.get("factory_code"),
            }

    # Non è l'ultimo admin (o non è admin): elimina solo il proprio account.
    ok = models.delete_user(user_id)
    if not ok:
        raise HTTPException(status_code=404, detail="user not found")
    return {"deleted": True, "factory_reset": False}


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
# BLE DEVICE REGISTRATION (associazione telefono BLE <-> utente)
# --------------------------------------------------------------------------------------
class BleRegisterRequest(BaseModel):
    """Registrazione dell'indirizzo BLE del telefono dell'utente."""
    ble_address: str


class BleInfoOut(BaseModel):
    """Info BLE registrata per l'utente."""
    ble_address: Optional[str] = None
    nearby_devices: int = 0


@app.post("/users/me/ble")
def register_ble(
    req: BleRegisterRequest,
    user: dict = Depends(_get_current_user),
):
    """Registra l'indirizzo BLE del telefono dell'utente.

    L'app invia il proprio MAC address Bluetooth; il backend lo associa
    all'utente così che l'event engine possa correlare i passaggi RFID
    con la presenza dell'utente alla porta.
    """
    from app.services.event_engine import register_ble_address
    ok = register_ble_address(user["id"], req.ble_address)
    if not ok:
        raise HTTPException(status_code=400, detail="invalid ble_address")
    return {"registered": True, "ble_address": req.ble_address.strip().upper()}


@app.get("/users/me/ble", response_model=BleInfoOut)
def get_ble_info(user: dict = Depends(_get_current_user)):
    """Restituisce l'indirizzo BLE registrato e il numero di device BLE vicini."""
    from app.services.event_engine import get_ble_address_for_user, get_all_nearby_ble
    addr = get_ble_address_for_user(user["id"])
    nearby = get_all_nearby_ble()
    return BleInfoOut(ble_address=addr, nearby_devices=len(nearby))


@app.delete("/users/me/ble")
def unregister_ble(user: dict = Depends(_get_current_user)):
    """Rimuove l'associazione BLE dell'utente."""
    from app.db.storage import DB_LOCK, load_db, save_db, find_by_id
    with DB_LOCK:
        db = load_db()
        record = find_by_id(db["users"], user["id"])
        if record:
            record["ble_address"] = None
            save_db(db)
    return {"removed": True}


class BleNearbyDevice(BaseModel):
    """Dispositivo BLE rilevato nelle vicinanze del Raspberry."""
    address: str
    name: str
    is_phone: bool
    last_seen_seconds_ago: float


@app.get("/ble/nearby", response_model=List[BleNearbyDevice])
def ble_nearby(_user: dict = Depends(_get_current_user)):
    """Lista dei dispositivi BLE rilevati nelle vicinanze dell'hub.

    Permette all'utente di identificare il proprio telefono nella lista
    e registrarlo come dispositivo BLE personale.
    """
    import time
    from app.services.event_engine import get_all_nearby_ble
    now = time.time()
    devices = get_all_nearby_ble()
    return [
        BleNearbyDevice(
            address=d.get("address", ""),
            name=d.get("name", "sconosciuto"),
            is_phone=bool(d.get("is_phone", False)),
            last_seen_seconds_ago=round(now - d.get("last_seen", now), 1),
        )
        for d in devices
    ]


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
