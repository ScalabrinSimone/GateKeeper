"""
GateKeeper – Modello Home (casa)
================================
Rappresenta una "casa" nel sistema. Ogni casa ha un admin e può avere
più utenti, oggetti RFID e dispositivi associati.

Una stessa installazione Raspberry gestisce una sola casa,
ma il modello è predisposto per multi-home in futuro.
"""

import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Home(Base):
    """
    Tabella: homes

    Colonne:
        id: UUID primario generato automaticamente.
        name: Nome della casa (es. "Casa Famiglia Rossi").
        invite_code: Codice univoco per invitare nuovi membri.
        created_at: Timestamp creazione (auto).

    Relazioni:
        users: Lista di utenti appartenenti a questa casa.
        rfid_objects: Lista di oggetti RFID registrati.
        gate_events: Lista di eventi porta registrati.
    """

    __tablename__ = "homes"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    # Codice di invito: stringa corta usata per il pairing nell'app
    invite_code: Mapped[str] = mapped_column(
        String(20), unique=True, nullable=False,
        default=lambda: str(uuid.uuid4())[:8].upper()
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )

    # ── Relazioni ──────────────────────────────────────────────────────────────
    # back_populates crea il collegamento bidirezionale:
    # home.users → lista utenti; user.home → oggetto casa
    users: Mapped[list["User"]] = relationship("User", back_populates="home")
    rfid_objects: Mapped[list["RfidObject"]] = relationship("RfidObject", back_populates="home")
    gate_events: Mapped[list["GateEvent"]] = relationship("GateEvent", back_populates="home")

    def __repr__(self) -> str:
        return f"<Home id={self.id!r} name={self.name!r}>"
