"""
models/event.py — Modello ORM per gli eventi RFID/BLE registrati.

Tabella: events

Ogni evento rappresenta un singolo rilevamento alla porta:
  - chi era presente (FK → users)
  - quali oggetti sono passati (JSON list di rfid_uid)
  - direzione (in/out)
  - tipo (exit/entry/alert/scan)
"""

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class EventType(str, enum.Enum):
    """
    Tipo di evento registrato dal sistema.

    Valori:
        EXIT:  uscita dalla porta.
        ENTRY: entrata in casa.
        ALERT: situazione anomala (bambino solo, oggetto sensibile, ecc.).
        SCAN:  scansione RFID generica (nessun movimento porta, solo rilevamento tag).
    """
    EXIT = "exit"
    ENTRY = "entry"
    ALERT = "alert"
    SCAN = "scan"


class EventDirection(str, enum.Enum):
    """Direzione del transito alla porta."""
    IN = "in"
    OUT = "out"


class Event(Base):
    """
    Singolo evento registrato dal gateway GateKeeper.

    Colonne:
        id (int): PK auto-increment.
        type (EventType): Tipo di evento.
        direction (EventDirection): Direzione (in/out).
        user_id (int|None): FK → users. None se l'utente non è identificato.
        object_uids (str): JSON array dei tag RFID rilevati durante l'evento.
                           Es. '["uid1", "uid2"]'
                           TODO: normalizzare in tabella pivot event_objects.
        alert_message (str|None): Messaggio di alert leggibile. Presente solo
                                   se type == ALERT.
        occurred_at (datetime): Timestamp dell'evento (impostato dal Raspberry,
                                NON dal server, per evitare drift di clock).
        created_at (datetime): Timestamp inserimento nel DB.
    """

    __tablename__ = "events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    type: Mapped[EventType] = mapped_column(Enum(EventType), nullable=False)
    direction: Mapped[EventDirection] = mapped_column(Enum(EventDirection), nullable=False)

    # Chiave esterna verso la tabella users
    # ondelete="SET NULL": se l'utente viene eliminato, l'evento resta ma user_id diventa NULL
    user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    # Relazione ORM: accedi all'utente con event.user
    user: Mapped["User | None"] = relationship(  # noqa: F821
        "User", back_populates="events", lazy="selectin"
    )

    # JSON array come stringa — semplice per ora, da normalizzare in futuro
    object_uids: Mapped[str] = mapped_column(Text, default="[]", nullable=False)
    alert_message: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # occurred_at viene inviato dal Raspberry nel payload, non generato dal server
    occurred_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    def __repr__(self) -> str:
        return f"<Event id={self.id} type={self.type} dir={self.direction} user_id={self.user_id}>"
