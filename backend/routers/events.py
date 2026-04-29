"""
GateKeeper – Router eventi porta
=================================
Endpoint per leggere e creare gli eventi GateEvent.

Percorsi:
    GET  /api/v1/events/        → lista eventi (con filtri)
    POST /api/v1/events/        → crea un evento (chiamato dal Raspberry)
    GET  /api/v1/events/{id}    → dettaglio evento

Nota:
    La creazione eventi viene fatta dal Raspberry (motore RFID/BLE),
    non direttamente dall'app Flutter. L'app legge solo gli eventi.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc

from database import get_db
from models.gate_event import GateEvent
from schemas.gate_event import EventCreate, EventOut

router = APIRouter()


@router.get("/", response_model=list[EventOut])
def list_events(
    home_id: str,
    # Filtri opzionali – l'app Flutter li usa per la schermata eventi
    direction: str | None = Query(None, description="IN | OUT"),
    event_type: str | None = Query(None, description="rfid_detected | ble_detected | manual"),
    user_id: str | None = Query(None, description="Filtra per utente"),
    limit: int = Query(50, le=200, description="Max eventi restituiti"),
    offset: int = Query(0, description="Paginazione"),
    db: Session = Depends(get_db),
):
    """Lista eventi della casa con filtri opzionali.

    Args:
        home_id: ID casa (obbligatorio).
        direction: Filtra per direzione (IN/OUT).
        event_type: Filtra per tipo evento.
        user_id: Filtra per utente specifico.
        limit: Numero massimo di risultati (default 50, max 200).
        offset: Quanti eventi saltare (per paginazione).
        db: Sessione DB.

    Returns:
        Lista di EventOut ordinata per timestamp decrescente (più recenti prima).
    """
    query = db.query(GateEvent).filter(GateEvent.home_id == home_id)

    # Applica i filtri solo se forniti
    if direction:
        query = query.filter(GateEvent.direction == direction.upper())
    if event_type:
        query = query.filter(GateEvent.event_type == event_type)
    if user_id:
        query = query.filter(GateEvent.user_id == user_id)

    # Ordina per timestamp decrescente e applica paginazione
    return (
        query
        .order_by(desc(GateEvent.timestamp))
        .offset(offset)
        .limit(limit)
        .all()
    )


@router.post("/", response_model=EventOut, status_code=201)
def create_event(payload: EventCreate, db: Session = Depends(get_db)):
    """Crea un nuovo evento porta.

    Chiamato dal Raspberry quando:
      - Il reader RFID rileva un tag (event_type="rfid_detected")
      - Il BLE scanner rileva/perde un telefono (event_type="ble_detected")

    Args:
        payload: Dati evento (EventCreate).
        db: Sessione DB.

    Returns:
        EventOut: Evento creato con id e timestamp assegnati.

    Note:
        TODO: dopo la creazione, inviare notifica push all'app se necessario
        TODO: aggiornare is_home di User/RfidObject in base alla direction
    """
    event = GateEvent(**payload.model_dump())
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


@router.get("/{event_id}", response_model=EventOut)
def get_event(event_id: str, db: Session = Depends(get_db)):
    """Dettaglio di un singolo evento.

    Args:
        event_id: UUID evento.

    Raises:
        HTTPException 404: Evento non trovato.
    """
    from fastapi import HTTPException
    event = db.query(GateEvent).filter(GateEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Evento non trovato")
    return event
