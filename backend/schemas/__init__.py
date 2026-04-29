# Package schemas – Pydantic models per validazione I/O delle API
# Gli schema separano la rappresentazione HTTP dai modelli ORM del database.
# Regola generale:
#   - Schema*Base:   campi comuni
#   - Schema*Create: input creazione (senza id, created_at)
#   - Schema*Update: input aggiornamento (tutti i campi opzionali)
#   - Schema*Out:    output risposta API (include id, timestamp)
from schemas.user import UserBase, UserCreate, UserUpdate, UserOut
from schemas.rfid_object import ObjectBase, ObjectCreate, ObjectUpdate, ObjectOut
from schemas.gate_event import EventBase, EventCreate, EventOut
from schemas.auth import TokenOut, LoginRequest

__all__ = [
    "UserBase", "UserCreate", "UserUpdate", "UserOut",
    "ObjectBase", "ObjectCreate", "ObjectUpdate", "ObjectOut",
    "EventBase", "EventCreate", "EventOut",
    "TokenOut", "LoginRequest",
]
