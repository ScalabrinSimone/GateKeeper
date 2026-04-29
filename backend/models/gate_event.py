"""
GateKeeper – Modello GateEvent
================================
Registra ogni evento di passaggio dalla porta.

Un evento viene creato dal Raspberry ogni volta che:
  - un tag RFID UHF viene letto dal reader (oggetto passa)
  - un MAC BLE viene rilevato/perso vicino alla porta (utente esce/entra)

Questi eventi sono il cuore del sistema: l'app li mostra in tempo reale
e la logica smart (notifiche, alert) si basa su di essi.
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, ForeignKey, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class GateEvent(Base):
    """
    Tabella: gate_events

    Colonne:
        id: UUID primario.
        home_id: FK alla casa.
        user_id: FK utente associato all'evento (può essere NULL se non identificato).
        rfid_object_id: FK oggetto RFID coinvolto (NULL se evento solo-utente).
        event_type: Tipo evento (rfid_detected | ble_detected | manual).
        direction: Direzione (IN = entra in casa | OUT = esce di casa).
        timestamp: Quando è avvenuto l'evento.
        note: Nota opzionale (es. "ombrello dimenticato").
        raw_data: JSON grezzo del payload hardware (per debug).
    """

    __tablename__ = "gate_events"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    home_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("homes.id"), nullable=False
    )

    # L'utente può essere NULL se il sistema non riesce ad associare l'evento
    user_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=True
    )

    # L'oggetto RFID è NULL per eventi BLE-only (rilevamento utente)
    rfid_object_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("rfid_objects.id"), nullable=True
    )

    # rfid_detected = tag RFID letto dal reader
    # ble_detected  = telefono rilevato/perso via BLE
    # manual        = evento creato manualmente dall'utente nell'app
    event_type: Mapped[str] = mapped_column(String(30), nullable=False)

    # IN = oggetto/utente entra in casa
    # OUT = oggetto/utente esce di casa
    direction: Mapped[str] = mapped_column(String(3), nullable=False)  # "IN" | "OUT"

    timestamp: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), index=True  # index per query veloci per data
    )

    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Payload grezzo dal reader (JSON stringa) – utile per debug hardware
    # TODO: strutturalo meglio con una tabella separata se il volume cresce
    raw_data: Mapped[str | None] = mapped_column(Text, nullable=True)

    # ── Relazioni ──────────────────────────────────────────────────────────────
    home: Mapped["Home"] = relationship("Home", back_populates="gate_events")
    user: Mapped["User | None"] = relationship("User", back_populates="gate_events")
    rfid_object: Mapped["RfidObject | None"] = relationship("RfidObject", back_populates="gate_events")

    def __repr__(self) -> str:
        return (
            f"<GateEvent id={self.id!r} type={self.event_type!r} "
            f"direction={self.direction!r} ts={self.timestamp!r}>"
        )
