"""
routers/users.py — CRUD utenti (richiede ruolo ADMIN).

Endpoint:
    GET    /api/users          — lista tutti gli utenti
    POST   /api/users          — crea un nuovo utente
    GET    /api/users/{id}     — dettaglio utente
    PATCH  /api/users/{id}     — aggiorna utente
    DELETE /api/users/{id}     — disattiva utente (soft delete)
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.deps import get_db, require_admin
from core.security import hash_password
from models.user import User
from schemas.user import UserCreate, UserRead, UserUpdate

router = APIRouter(prefix="/api/users", tags=["users"])


@router.get("/", response_model=list[UserRead])
async def list_users(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),  # solo admin possono vedere tutti gli utenti
):
    """Restituisce la lista di tutti gli utenti registrati."""
    result = await db.execute(select(User).order_by(User.created_at))
    return result.scalars().all()


@router.post("/", response_model=UserRead, status_code=status.HTTP_201_CREATED)
async def create_user(
    body: UserCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Crea un nuovo utente.

    Raises:
        409: se l'email è già registrata.
    """
    # Controlla duplicati
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = User(
        name=body.name,
        email=body.email,
        hashed_password=hash_password(body.password),  # mai salvare plain-text!
        role=body.role,
        ble_mac=body.ble_mac,
    )
    db.add(user)
    await db.flush()   # assegna l'id senza fare commit (il commit è in get_db)
    return user


@router.get("/{user_id}", response_model=UserRead)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """Dettaglio di un singolo utente."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.patch("/{user_id}", response_model=UserRead)
async def update_user(
    user_id: int,
    body: UserUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Aggiorna parzialmente un utente.

    Solo i campi presenti nel body vengono modificati (PATCH semantics).
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # model_dump(exclude_unset=True) restituisce solo i campi inviati nel body
    # così non sovrascriviamo campi che il client non ha toccato
    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)

    await db.flush()
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def deactivate_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    """
    Disattiva un utente (soft delete: is_active = False).

    Non eliminiamo fisicamente il record perché gli eventi
    storici hanno FK verso questo utente.

    TODO: decidere policy — hard delete con CASCADE o soft delete.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    await db.flush()
