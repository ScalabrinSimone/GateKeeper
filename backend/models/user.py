"""
GateKeeper – Modello User
==========================
Rappresenta un utente del sistema (Admin, Adulto o Bambino).

Ruoli:
    admin   → gestisce casa e utenti, accesso completo
    adult   → accesso completo agli eventi e oggetti
    child   → accesso limitato, non può gestire utenti/oggetti

L'identificazione BLE avviene tramite il campo `ble_mac_address`:
il Raspberry scannerizza i dispositivi Bluetooth vicini e confronta
i MAC address con quelli salvati qui per capire chi è presente.
"""

import uuid
from datetime import datetime

from sqlalchemy import String, Boolean, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class User(Base):
    """
    Tabella: users

    Colonne:
        id: UUID primario.
        home_id: FK alla casa di appartenenza.
        username: Nome utente univoco nella casa.
        email: Email (usata per il login).
        hashed_password: Password cifrata con bcrypt (NON salvare mai la password in chiaro).
        role: Ruolo (admin / adult / child).
        ble_mac_address: MAC address Bluetooth del telefono dell'utente.
            Usato dal Raspberry per rilevare la presenza via BLE.
        is_active: False = utente disabilitato (non può fare login).
        is_home: True se il sistema ha rilevato l'utente IN casa.
        last_seen: Ultimo timestamp di rilevazione BLE.
        avatar_color: Colore HEX per l'avatar nell'app (es. "#FFA400").
        created_at: Timestamp creazione.
    """

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    home_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("homes.id"), nullable=False
    )
    username: Mapped[str] = mapped_column(String(50), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)

    # La password viene sempre salvata hashata, mai in chiaro
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)

    # admin | adult | child
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="adult")

    # MAC address BLE del telefono – usato per il rilevamento presenza
    # Formato: "AA:BB:CC:DD:EE:FF" (case insensitive)
    # TODO: su iOS il MAC è randomizzato, valuta UUID iBeacon come alternativa
    ble_mac_address: Mapped[str | None] = mapped_column(String(17), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Stato presenza – aggiornato dal motore BLE/RFID del Raspberry
    is_home: Mapped[bool] = mapped_column(Boolean, default=False)
    last_seen: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    # Colore avatar HEX per l'app
    avatar_color: Mapped[str] = mapped_column(String(7), default="#00767A")

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )

    # ── Relazioni ──────────────────────────────────────────────────────────────
    home: Mapped["Home"] = relationship("Home", back_populates="users")
    gate_events: Mapped[list["GateEvent"]] = relationship("GateEvent", back_populates="user")

    def __repr__(self) -> str:
        return f"<User id={self.id!r} username={self.username!r} role={self.role!r}>"
