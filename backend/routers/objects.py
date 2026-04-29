"""
GateKeeper – Router oggetti RFID
=================================
Endpoint CRUD per la gestione degli oggetti con tag RFID.

Percorsi:
    GET    /api/v1/objects/             → lista oggetti della casa
    POST   /api/v1/objects/             → registra nuovo oggetto
    GET    /api/v1/objects/{object_id}  → dettaglio oggetto
    PUT    /api/v1/objects/{object_id}  → aggiorna oggetto
    DELETE /api/v1/objects/{object_id}  → elimina oggetto
    PATCH  /api/v1/objects/{object_id}/presence → aggiorna stato IN/OUT
        (chiamato dal Raspberry quando legge un tag RFID)
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models.rfid_object import RfidObject
from schemas.rfid_object import ObjectCreate, ObjectUpdate, ObjectOut

router = APIRouter()


@router.get("/", response_model=list[ObjectOut])
def list_objects(home_id: str, db: Session = Depends(get_db)):
    """Lista tutti gli oggetti RFID registrati per una casa.

    Args:
        home_id: ID casa (query param).
        db: Sessione DB.
    """
    return db.query(RfidObject).filter(RfidObject.home_id == home_id).all()


@router.post("/", response_model=ObjectOut, status_code=201)
def create_object(payload: ObjectCreate, db: Session = Depends(get_db)):
    """Registra un nuovo oggetto con tag RFID.

    L'EPC deve essere univoco nel sistema (letto dal reader durante il pairing).

    Args:
        payload: Dati oggetto (ObjectCreate).
        db: Sessione DB.

    Raises:
        HTTPException 400: EPC già registrato.
    """
    if db.query(RfidObject).filter(RfidObject.epc == payload.epc).first():
        raise HTTPException(status_code=400, detail="EPC già registrato")
    obj = RfidObject(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{object_id}", response_model=ObjectOut)
def get_object(object_id: str, db: Session = Depends(get_db)):
    """Dettaglio di un oggetto RFID.

    Args:
        object_id: UUID oggetto.
    """
    obj = db.query(RfidObject).filter(RfidObject.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Oggetto non trovato")
    return obj


@router.put("/{object_id}", response_model=ObjectOut)
def update_object(object_id: str, payload: ObjectUpdate, db: Session = Depends(get_db)):
    """Aggiorna nome, icona, categoria ecc. di un oggetto.

    Args:
        object_id: UUID oggetto.
        payload: Campi da aggiornare.
    """
    obj = db.query(RfidObject).filter(RfidObject.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Oggetto non trovato")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{object_id}", status_code=204)
def delete_object(object_id: str, db: Session = Depends(get_db)):
    """Elimina un oggetto RFID dal registro.

    Args:
        object_id: UUID oggetto.
    """
    obj = db.query(RfidObject).filter(RfidObject.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Oggetto non trovato")
    db.delete(obj)
    db.commit()


@router.patch("/{object_id}/presence", response_model=ObjectOut)
def update_object_presence(
    object_id: str,
    direction: str,  # "IN" | "OUT"
    db: Session = Depends(get_db),
):
    """Aggiorna lo stato presenza di un oggetto (IN casa / OUT casa).

    Chiamato dal Raspberry ogni volta che il reader RFID rileva il tag.
    Non dall'app Flutter.

    Args:
        object_id: UUID oggetto.
        direction: "IN" se l'oggetto entra, "OUT" se esce.
        db: Sessione DB.

    Returns:
        ObjectOut: Oggetto con is_home e last_seen aggiornati.
    """
    obj = db.query(RfidObject).filter(RfidObject.id == object_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Oggetto non trovato")
    obj.is_home = direction.upper() == "IN"
    obj.last_seen = datetime.now(timezone.utc)
    db.commit()
    db.refresh(obj)
    # TODO: qui puoi triggerare una notifica push all'app
    return obj
