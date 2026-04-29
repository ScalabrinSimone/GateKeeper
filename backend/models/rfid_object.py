"""
models/rfid_object.py — Modello ORM per gli oggetti tracciati via RFID.

Tabella: rfid_objects

Ogni riga rappresenta un oggetto fisico (chiavi, ombrello, zaino, ecc.)
cui è stato associato un tag RFID UHF.
"""

import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class ObjectStatus(str, enum.Enum):
    """
    Stato corrente dell'oggetto RFID.

    Valori:
        HOME:    l'oggetto si trova dentro casa (rilevato in ingresso o non uscito).
        AWAY:    l'oggetto è fuori casa (rilevato in uscita).
        UNKNOWN: stato non determinato (es. primo avvio, tag mai rilevato).
    """
    HOME = "home"
    AWAY = "away"
    UNKNOWN = "unknown"


class RfidObject(Base):
    """
    Oggetto fisico tracciato con tag RFID UHF.

    Colonne:
        id (int): PK auto-increment.
        name (str): Nome leggibile (es. "Chiavi di casa").
        rfid_uid (str): UID univoco del tag RFID (letto dal reader UHF).
        category (str): Categoria libera (es. "Keys", "Bag", "Documents").
        status (ObjectStatus): Stato corrente (home/away/unknown).
        is_sensitive (bool): Se True, genera alert quando portato fuori.
                             Utile per passaporti, medicinali, ecc.
        last_seen_at (datetime|None): Ultima volta che il tag è stato rilevato.
        created_at (datetime): Timestamp creazione record.
    """

    __tablename__ = "rfid_objects"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    # L'UID è la stringa esadecimale che il reader RFID UHF invia al Raspberry
    # Es. "E2000017221102141820B4E0" — deve essere univoco per ogni tag
    rfid_uid: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    category: Mapped[str] = mapped_column(String(80), default="Generic", nullable=False)
    status: Mapped[ObjectStatus] = mapped_column(
        Enum(ObjectStatus), default=ObjectStatus.UNKNOWN, nullable=False
    )
    # Oggetti sensibili: generano notifica push anche senza bambini coinvolti
    is_sensitive: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    def __repr__(self) -> str:
        return f"<RfidObject id={self.id} uid={self.rfid_uid!r} status={self.status}>"
