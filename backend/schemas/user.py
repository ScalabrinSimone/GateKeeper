"""
GateKeeper – Schema User
=========================
Pydantic models per validazione input/output degli endpoint utenti.
"""

from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    """Campi comuni a tutti gli schema User."""
    username: str
    email: EmailStr
    role: str = "adult"  # admin | adult | child
    avatar_color: str = "#00767A"
    ble_mac_address: str | None = None


class UserCreate(UserBase):
    """Input per creare un nuovo utente.

    Attributi aggiuntivi:
        password: Password in chiaro – verrà hashata prima del salvataggio.
        home_id: ID della casa a cui associare l'utente.
    """
    password: str
    home_id: str


class UserUpdate(BaseModel):
    """Input per aggiornare un utente – tutti i campi sono opzionali."""
    username: str | None = None
    email: EmailStr | None = None
    role: str | None = None
    avatar_color: str | None = None
    ble_mac_address: str | None = None
    is_active: bool | None = None


class UserOut(UserBase):
    """Output API – include i campi calcolati/di sistema.

    Attributi:
        id: UUID utente.
        is_home: True se il sistema rileva l'utente in casa (stato BLE).
        last_seen: Ultimo timestamp di rilevazione BLE.
        created_at: Timestamp creazione account.
    """
    id: str
    is_home: bool
    is_active: bool
    last_seen: datetime | None
    created_at: datetime

    # from_attributes=True permette di creare lo schema da un oggetto ORM SQLAlchemy
    model_config = {"from_attributes": True}
