"""
models/user.py — Modello ORM per gli utenti di casa.

Tabella: users

Relazioni:
- Un utente può avere zero o più eventi associati (relationship events).
"""

import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class UserRole(str, enum.Enum):
    """
    Ruolo dell'utente nel sistema GateKeeper.

    Valori:
        ADMIN:  può gestire tutti gli utenti, oggetti e configurazioni.
        ADULT:  accesso completo alle funzionalità, non può gestire altri admin.
        CHILD:  accesso limitato; genera alert speciali se esce senza supervisione.
    """
    ADMIN = "admin"
    ADULT = "adult"
    CHILD = "child"


class User(Base):
    """
    Utente registrato nella casa GateKeeper.

    Colonne:
        id (int): PK auto-increment.
        name (str): Nome visualizzato.
        email (str): Email univoca (usata per il login).
        hashed_password (str): Password hashata con bcrypt. Mai salvare la plain-text!
        role (UserRole): Ruolo dell'utente (admin/adult/child).
        ble_mac (str|None): Indirizzo MAC del dispositivo BLE associato.
                            Usato per identificare l'utente vicino alla porta.
        is_active (bool): Se False, l'utente non può fare login.
        created_at (datetime): Timestamp creazione (auto-set dal DB).
    """

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole), default=UserRole.ADULT, nullable=False
    )
    # Indirizzo MAC BLE del telefono dell'utente (es. "AA:BB:CC:DD:EE:FF")
    # Viene rilevato dallo scanner BLE sul Raspberry quando l'utente è vicino alla porta
    ble_mac: Mapped[str | None] = mapped_column(String(17), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # server_default="CURRENT_TIMESTAMP" garantisce che il DB imposti il valore
    # anche se si inserisce il record senza passare created_at
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    # Relazione ORM: accedi agli eventi di un utente con user.events
    # back_populates="user" specifica il lato opposto della relazione in Event
    events: Mapped[list["Event"]] = relationship(  # noqa: F821
        "Event", back_populates="user", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r} role={self.role}>"
