from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from app.db import models

app = FastAPI(title="Device Access API")

# Pydantic request/response models
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

# Endpoints
@app.post('/users', response_model=UserOut)
def create_user(req: UserCreate):
    """Crea un nuovo utente. Restituisce l'ID e lo username."""
    try:
        user_id = models.create_user(req.username, req.password)
        return {"id": user_id, "username": req.username}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get('/users/{user_id}', response_model=UserOut)
def get_user(user_id: int):
    """Recupera un utente per ID."""
    user = models.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail='User not found')
    return {"id": user['id'], "username": user['username']}

@app.post('/devices', response_model=DeviceOut)
def add_device(req: DeviceCreate):
    """Aggiunge un nuovo dispositivo."""
    device_id = models.create_device(req.name)
    return {"id": device_id, "name": req.name}

@app.get('/devices', response_model=List[DeviceOut])
def list_devices():
    """Elenca tutti i dispositivi."""
    devices = models.list_devices()
    return devices

@app.post('/associate')
def associate(req: AssociateRequest):
    """Associa un utente a un dispositivo."""
    try:
        assoc_id = models.associate_user_device(req.user_id, req.device_id)
        return {"association_id": assoc_id}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post('/logs', response_model=LogOut)
def add_log(req: LogCreate):
    """Crea un log di accesso/uscita."""
    try:
        log_id = models.create_log(req.user_id, req.device_id, req.action)
        # Recupera il log appena creato per rispondere
        logs = models.list_logs()
        for l in logs:
            if l['id'] == log_id:
                return l
        raise HTTPException(status_code=500, detail='Log created but not found')
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get('/logs', response_model=List[LogOut])
def get_logs(user_id: Optional[int] = None, device_id: Optional[int] = None):
    """Recupera i log, filtrabili per utente o dispositivo."""
    logs = models.list_logs(user_id=user_id, device_id=device_id)
    return logs
