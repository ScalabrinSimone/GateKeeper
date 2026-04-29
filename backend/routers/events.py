"""
routers/events.py — Lettura eventi e ricezione eventi dal Raspberry.

Endpoint:
    GET  /api/events            — lista eventi paginata (query params: skip, limit, type)
    POST /api/events            — riceve un nuovo evento dal Raspberry (no auth richiesta
                                   dalla LAN, TODO: aggiungere API key)
    GET  /api/events/{id}       — dettaglio evento

Nota sul POST /api/events:
    Il Raspberry invia eventi senza autenticazione JWT perché è un device
    interno alla LAN. In produzione aggiungi un header X-Device-Key.
"""

import json
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.deps import get_current_user, get_db
from models.event import Event
from models.rfid_object import ObjectStatus, RfidObject
from models.user import User
from schemas.event import EventCreate, EventRead

router = APIRouter(prefix="/api/events", tags=["events"])


@router.get("/", response_model=list[EventRead])
async def list_events(
    skip: int = Query(default=0, ge=0, description="Offset per la paginazione"),
    limit: int = Query(default=50, le=200, description="Numero massimo di eventi restituiti"),
    type: str | None = Query(default=None, description="Filtra per tipo: exit|entry|alert|scan"),
    db: AsyncSession = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    """
    Lista eventi in ordine cronologico inverso (più recente prima).

    Supporta paginazione via skip+limit e filtro per tipo.
    TODO: aggiungere filtro per data (from_date, to_date).
    TODO: aggiungere filtro per user_id.
    """
    query = select(Event).order_by(Event.occurred_at.desc()).offset(skip).limit(limit)

    if type:
        # Filtro opzionale per tipo evento
        query = query.where(Event.type == type)

    result = await db.execute(query)
    events = result.scalars().all()

    # Deserializza object_uids da stringa JSON a lista Python
    # (nel DB è salvato come stringa es. '["uid1","uid2"]')
    for ev in events:
        if isinstance(ev.object_uids, str):
            ev.object_uids = json.loads(ev.object_uids)

    return events


@router.post("/", response_model=EventRead, status_code=201)
async def receive_event(
    body: EventCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Riceve un evento dal Raspberry Pi e aggiorna lo stato degli oggetti.

    Flusso:
        1. Crea il record Event nel DB.
        2. Per ogni UID RFID nell'evento, aggiorna lo stato dell'oggetto
           (away se direction=out, home se direction=in).
        3. TODO: inviare notifica push via FCM/APNs.
        4. TODO: verificare policy bambini (se user ha ruolo CHILD + direction=out
                 senza adulti rilevati via BLE → genera alert automatico).

    Note sicurezza:
        Questo endpoint non richiede JWT perchè è chiamato dal Raspberry
        sulla LAN locale. TODO: aggiungere header X-Device-Key per autenticare
        il Raspberry e prevenire spoofing.
    """
    event = Event(
        type=body.type,
        direction=body.direction,
        user_id=body.user_id,
        # Serializza la lista Python in stringa JSON per salvarla nel DB
        object_uids=json.dumps(body.object_uids),
        alert_message=body.alert_message,
        occurred_at=body.occurred_at,
    )
    db.add(event)

    # Aggiorna lo stato di ogni oggetto RFID coinvolto nell'evento
    for uid in body.object_uids:
        result = await db.execute(
            select(RfidObject).where(RfidObject.rfid_uid == uid)
        )
        obj = result.scalar_one_or_none()
        if obj:
            # in = oggetto rientrato in casa, out = oggetto uscito
            obj.status = (
                ObjectStatus.HOME if body.direction.value == "in" else ObjectStatus.AWAY
            )
            obj.last_seen_at = body.occurred_at
        # TODO: se uid non trovato, considerare di creare un oggetto "Unknown" automaticamente

    await db.flush()

    # Deserializza per la risposta
    event.object_uids = body.object_uids  # type: ignore[assignment]
    return event


@router.get("/{event_id}", response_model=EventRead)
async def get_event(
    event_id: int,
    db: AsyncSession = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    """Dettaglio di un singolo evento."""
    ev = await db.get(Event, event_id)
    if not ev:
        raise HTTPException(status_code=404, detail="Event not found")
    if isinstance(ev.object_uids, str):
        ev.object_uids = json.loads(ev.object_uids)
    return ev
