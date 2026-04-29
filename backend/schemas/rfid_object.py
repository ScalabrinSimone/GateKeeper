"""
GateKeeper – Schema RfidObject
================================
Pydantic models per validazione input/output degli endpoint oggetti RFID.
"""

from datetime import datetime
from pydantic import BaseModel


class ObjectBase(BaseModel):
    """Campi comuni a tutti gli schema RfidObject."""
    name: str
    icon: str = "label"
    category: str = "other"  # keys | umbrella | bag | phone | other
    is_sensitive: bool = False
    color: str = "#00767A"
    owner_id: str | None = None


class ObjectCreate(ObjectBase):
    """Input per registrare un nuovo oggetto RFID.

    Attributi aggiuntivi:
        epc: EPC del tag RFID letto dal reader durante il pairing.
        home_id: ID della casa.
    """
    epc: str
    home_id: str


class ObjectUpdate(BaseModel):
    """Input aggiornamento – tutti i campi opzionali."""
    name: str | None = None
    icon: str | None = None
    category: str | None = None
    is_sensitive: bool | None = None
    color: str | None = None
    owner_id: str | None = None


class ObjectOut(ObjectBase):
    """Output API.

    Attributi:
        id: UUID oggetto.
        epc: EPC del tag RFID.
        is_home: True se l'oggetto risulta in casa.
        last_seen: Ultimo timestamp RFID.
        created_at: Timestamp creazione.
    """
    id: str
    epc: str
    is_home: bool
    last_seen: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}
