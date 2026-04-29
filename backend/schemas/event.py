"""
schemas/event.py — Pydantic schemas per Event.
"""

from datetime import datetime

from pydantic import BaseModel, Field

from models.event import EventDirection, EventType


class EventCreate(BaseModel):
    """
    Body POST /api/events — inviato dal Raspberry quando rileva un evento.

    Attributi:
        type: Tipo evento (exit/entry/alert/scan).
        direction: Direzione (in/out).
        user_id: ID utente associato (opzionale, identificato via BLE MAC).
        object_uids: Lista di UID RFID rilevati durante l'evento.
        alert_message: Messaggio di alert (solo se type=alert).
        occurred_at: Timestamp dell'evento (impostato dal Raspberry).
    """

    type: EventType
    direction: EventDirection
    user_id: int | None = None
    object_uids: list[str] = Field(default_factory=list)
    alert_message: str | None = Field(default=None, max_length=500)
    occurred_at: datetime


class EventRead(BaseModel):
    """
    Risposta GET /api/events.

    object_uids viene restituito come lista (deserializzata dal JSON string nel DB).
    """

    id: int
    type: EventType
    direction: EventDirection
    user_id: int | None
    object_uids: list[str]
    alert_message: str | None
    occurred_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}
