"""
GateKeeper – Modello RfidObject
================================
Rappresenta un oggetto fisico con tag RFID UHF (es. chiavi, ombrello, zaino).

Come funziona il tracking:
  1. Il reader RFID UHF rileva il tag quando l'oggetto passa vicino alla porta
  2. Confronta l'EPC (Electronic Product Code) del tag con questa tabella
  3. Crea un GateEvent con direction=IN o OUT
  4. Aggiorna is_home e last_seen
"""

import uuid
from datetime import datetime

from sqlalchemy import String, Boolean, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class RfidObject(Base):
    """
    Tabella: rfid_objects

    Colonne:
        id: UUID primario.
        home_id: FK alla casa.
        name: Nome leggibile dell'oggetto (es. "Chiavi di casa").
        icon: Nome icona Material/Cupertino da mostrare nell'app.
        category: Categoria (keys | umbrella | bag | phone | other).
        epc: EPC del tag RFID UHF (stringa hex, univoca per tag).
            Esempio: "E2003412012345678901234A"
        is_sensitive: True = notifica sempre se l'oggetto esce senza utente.
        is_home: True se l'oggetto risulta IN casa.
        last_seen: Ultimo timestamp di lettura RFID.
        owner_id: FK utente proprietario (opzionale).
        color: Colore HEX per l'icona nell'app.
        created_at: Timestamp creazione.
    """

    __tablename__ = "rfid_objects"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    home_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("homes.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Nome icona da usare nell'app Flutter (es. "key", "umbrella", "backpack")
    icon: Mapped[str] = mapped_column(String(50), default="label")

    # Categoria per filtri e notifiche smart
    category: Mapped[str] = mapped_column(String(30), default="other")

    # EPC del tag RFID – letto dal reader UHF alla porta
    # TODO: durante il pairing dell'oggetto, fai leggere l'EPC al reader e salvalo qui
    epc: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)

    # Se True, invia notifica ogni volta che l'oggetto esce senza un utente
    is_sensitive: Mapped[bool] = mapped_column(Boolean, default=False)

    # Stato presenza – aggiornato dal motore RFID
    is_home: Mapped[bool] = mapped_column(Boolean, default=True)
    last_seen: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    # Proprietario opzionale (un oggetto può non avere un proprietario specifico)
    owner_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=True
    )

    # Colore HEX per l'icona nell'app
    color: Mapped[str] = mapped_column(String(7), default="#00767A")

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )

    # ── Relazioni ──────────────────────────────────────────────────────────────
    home: Mapped["Home"] = relationship("Home", back_populates="rfid_objects")
    owner: Mapped["User | None"] = relationship("User", foreign_keys=[owner_id])
    gate_events: Mapped[list["GateEvent"]] = relationship("GateEvent", back_populates="rfid_object")

    def __repr__(self) -> str:
        return f"<RfidObject id={self.id!r} name={self.name!r} epc={self.epc!r}>"
