"""
GateKeeper – Schema GateEvent
================================
Pydantic models per validazione input/output degli endpoint eventi.
"""

from datetime import datetime
from pydantic import BaseModel


class EventBase(BaseModel):
    """Campi comuni."""
    event_type: str       # rfid_detected | ble_detected | manual
    direction: str        # IN | OUT
    user_id: str | None = None
    rfid_object_id: str | None = None
    note: str | None = None


class EventCreate(EventBase):
    """Input per creare un evento (chiamato dal Raspberry, non dall'app).

    Attributi:
        home_id: ID della casa.
        raw_data: Payload grezzo JSON dal reader hardware (stringa).
    """
    home_id: str
    raw_data: str | None = None


class EventOut(EventBase):
    """Output API – include id e timestamp."""
    id: str
    home_id: str
    timestamp: datetime

    model_config = {"from_attributes": True}
