"""
schemas/user.py — Pydantic schemas per l'entità User.
"""

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from models.user import UserRole


class UserCreate(BaseModel):
    """
    Body della richiesta POST /api/users.

    Attributi:
        name: Nome visualizzato (min 2, max 100 caratteri).
        email: Email valida e univoca.
        password: Password in chiaro — viene hashata prima del salvataggio.
        role: Ruolo assegnato (default ADULT).
        ble_mac: MAC address BLE del telefono (opzionale, formato XX:XX:XX:XX:XX:XX).
    """

    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=6, description="Almeno 6 caratteri")
    role: UserRole = UserRole.ADULT
    ble_mac: str | None = Field(
        default=None,
        pattern=r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$",
        description="MAC address BLE nel formato AA:BB:CC:DD:EE:FF",
    )


class UserUpdate(BaseModel):
    """
    Body della richiesta PATCH /api/users/{id}.

    Tutti i campi sono opzionali: si aggiorna solo ciò che viene inviato.
    """

    name: str | None = Field(default=None, min_length=2, max_length=100)
    role: UserRole | None = None
    ble_mac: str | None = Field(
        default=None,
        pattern=r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$",
    )
    is_active: bool | None = None


class UserRead(BaseModel):
    """
    Risposta delle API GET /api/users e GET /api/users/{id}.

    Nota: 'hashed_password' NON è incluso per sicurezza.
    """

    id: int
    name: str
    email: str
    role: UserRole
    ble_mac: str | None
    is_active: bool
    created_at: datetime

    # model_config with from_attributes=True permette di costruire
    # questo schema direttamente da un oggetto ORM SQLAlchemy
    model_config = {"from_attributes": True}
