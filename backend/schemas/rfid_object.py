"""
schemas/rfid_object.py — Pydantic schemas per RfidObject.
"""

from datetime import datetime

from pydantic import BaseModel, Field

from models.rfid_object import ObjectStatus


class RfidObjectCreate(BaseModel):
    """
    Body POST /api/objects.

    Attributi:
        name: Nome leggibile dell'oggetto.
        rfid_uid: UID univoco letto dal tag RFID (stringa hex).
        category: Categoria libera (es. "Keys", "Bag").
        is_sensitive: Se True genera alert quando portato fuori.
    """

    name: str = Field(..., min_length=1, max_length=150)
    rfid_uid: str = Field(..., min_length=4, max_length=64)
    category: str = Field(default="Generic", max_length=80)
    is_sensitive: bool = False


class RfidObjectUpdate(BaseModel):
    """Body PATCH /api/objects/{id} — tutti i campi opzionali."""

    name: str | None = Field(default=None, max_length=150)
    category: str | None = Field(default=None, max_length=80)
    status: ObjectStatus | None = None
    is_sensitive: bool | None = None


class RfidObjectRead(BaseModel):
    """Risposta GET /api/objects."""

    id: int
    name: str
    rfid_uid: str
    category: str
    status: ObjectStatus
    is_sensitive: bool
    last_seen_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}
