"""
routers/objects.py — CRUD oggetti RFID.

Endpoint:
    GET    /api/objects        — lista oggetti
    POST   /api/objects        — registra nuovo oggetto (admin)
    GET    /api/objects/{id}   — dettaglio oggetto
    PATCH  /api/objects/{id}   — aggiorna oggetto (admin)
    DELETE /api/objects/{id}   — elimina oggetto (admin)
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.deps import get_current_user, get_db, require_admin
from models.rfid_object import RfidObject
from models.user import User
from schemas.rfid_object import RfidObjectCreate, RfidObjectRead, RfidObjectUpdate

router = APIRouter(prefix="/api/objects", tags=["objects"])


@router.get("/", response_model=list[RfidObjectRead])
async def list_objects(
    db: AsyncSession = Depends(get_db),
    _user: User = Depends(get_current_user),  # tutti gli utenti loggati possono vedere gli oggetti
):
    """Lista tutti gli oggetti RFID registrati."""
    result = await db.execute(select(RfidObject).order_by(RfidObject.name))
    return result.scalars().all()


@router.post("/", response_model=RfidObjectRead, status_code=status.HTTP_201_CREATED)
async def create_object(
    body: RfidObjectCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Registra un nuovo oggetto RFID.

    Raises:
        409: se l'UID RFID è già registrato.
    """
    existing = await db.execute(
        select(RfidObject).where(RfidObject.rfid_uid == body.rfid_uid)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="RFID UID already registered",
        )

    obj = RfidObject(**body.model_dump())
    db.add(obj)
    await db.flush()
    return obj


@router.get("/{object_id}", response_model=RfidObjectRead)
async def get_object(
    object_id: int,
    db: AsyncSession = Depends(get_db),
    _user: User = Depends(get_current_user),
):
    """Dettaglio di un singolo oggetto RFID."""
    obj = await db.get(RfidObject, object_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    return obj


@router.patch("/{object_id}", response_model=RfidObjectRead)
async def update_object(
    object_id: int,
    body: RfidObjectUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Aggiorna parzialmente un oggetto (solo admin)."""
    obj = await db.get(RfidObject, object_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")

    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)

    await db.flush()
    return obj


@router.delete("/{object_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_object(
    object_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Elimina un oggetto RFID dal sistema."""
    obj = await db.get(RfidObject, object_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")
    await db.delete(obj)
