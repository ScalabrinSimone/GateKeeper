from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from app.db import models

app = FastAPI(title="Device Access API")


# --- Modelli Pydantic ---
class UserCreate(BaseModel):
    username: str
    password: str


class UserOut(BaseModel):
    id: int
    username: str


class DeviceCreate(BaseModel):
    name: str


class DeviceOut(BaseModel):
    id: int
    name: str


class AssociateRequest(BaseModel):
    user_id: int
    device_id: int


class LogCreate(BaseModel):
    user_id: int
    device_id: int
    action: str  # 'ENTRATO' or 'USCITO'


class LogOut(BaseModel):
    id: int
    user_id: int
    device_id: int
    action: str
    created_at: str


# --- Endpoints (semplici, commentati in italiano) ---


@app.post('/users', response_model=UserOut)
def create_user(req: UserCreate):
    """
    Crea un nuovo utente.

    - Riceve username e password in chiaro (solo per test).
    - Usa `models.create_user` per inserire l'utente nel DB.
    - Restituisce l'`id` creato e lo `username`.
    """
    try:
        user_id = models.create_user(req.username, req.password)
        return {"id": user_id, "username": req.username}
    except ValueError as e:
        # Valida errori e restituisce 400 con dettaglio leggibile
        raise HTTPException(status_code=400, detail=str(e))


@app.get('/users/{user_id}', response_model=UserOut)
def get_user(user_id: int):
    """
    Recupera un utente per `id`.

    Ritorna 404 se l'utente non esiste.
    """
    user = models.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail='User not found')
    return {"id": user['id'], "username": user['username']}


@app.post('/devices', response_model=DeviceOut)
def add_device(req: DeviceCreate):
    """
    Aggiunge un nuovo dispositivo semplice.

    Restituisce l'id del dispositivo creato e il suo nome.
    """
    device_id = models.create_device(req.name)
    return {"id": device_id, "name": req.name}


@app.get('/devices', response_model=List[DeviceOut])
def list_devices():
    """Elenca tutti i dispositivi registrati."""
    devices = models.list_devices()
    return devices


@app.post('/associate')
def associate(req: AssociateRequest):
    """
    Associa un utente a un dispositivo.

    Se i valori non sono validi, `models` solleverà eccezioni che
    qui vengono convertite in `HTTPException` con codice 400.
    """
    try:
        assoc_id = models.associate_user_device(req.user_id, req.device_id)
        return {"association_id": assoc_id}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post('/logs', response_model=LogOut)
def add_log(req: LogCreate):
    """
    Crea un record di log (ENTRATO/USCITO).

    Restituisce il log appena creato. Se per qualche motivo il log
    non è presente dopo l'inserimento, ritorna 500 (caso raro).
    """
    try:
        log_id = models.create_log(req.user_id, req.device_id, req.action)
        logs = models.list_logs()
        for l in logs:
            if l['id'] == log_id:
                return l
        raise HTTPException(status_code=500, detail='Log created but not found')
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get('/logs', response_model=List[LogOut])
def get_logs(user_id: Optional[int] = None, device_id: Optional[int] = None):
    """
    Recupera i log, con filtri opzionali per `user_id` e `device_id`.
    """
    logs = models.list_logs(user_id=user_id, device_id=device_id)
    return logs
