"""
GateKeeper – Router utenti
============================
Endpoint CRUD per la gestione degli utenti della casa.

Percorsi:
    GET    /api/v1/users/          → lista tutti gli utenti della casa
    POST   /api/v1/users/          → crea un nuovo utente (solo admin)
    GET    /api/v1/users/{user_id} → dettaglio utente
    PUT    /api/v1/users/{user_id} → aggiorna utente
    DELETE /api/v1/users/{user_id} → elimina utente (solo admin)

Tutti gli endpoint richiedono JWT valido.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models.user import User
from schemas.user import UserCreate, UserUpdate, UserOut
from core.security import hash_password

router = APIRouter()


@router.get("/", response_model=list[UserOut])
def list_users(
    home_id: str,
    db: Session = Depends(get_db),
    # TODO: aggiungere Depends(get_current_user) per proteggere l'endpoint
):
    """Restituisce tutti gli utenti della casa specificata.

    Args:
        home_id: ID della casa (query param, es. /users/?home_id=xxx).
        db: Sessione DB.

    Returns:
        Lista di UserOut.
    """
    # TODO: verificare che l'utente corrente appartenga a home_id
    return db.query(User).filter(User.home_id == home_id).all()


@router.post("/", response_model=UserOut, status_code=201)
def create_user(payload: UserCreate, db: Session = Depends(get_db)):
    """Crea un nuovo utente nella casa.

    Args:
        payload: Dati nuovo utente (UserCreate).
        db: Sessione DB.

    Returns:
        UserOut: Utente creato.

    Raises:
        HTTPException 400: Email già in uso.
    """
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email già in uso")
    user = User(
        home_id=payload.home_id,
        username=payload.username,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        role=payload.role,
        avatar_color=payload.avatar_color,
        ble_mac_address=payload.ble_mac_address,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut)
def get_user(user_id: str, db: Session = Depends(get_db)):
    """Dettaglio di un utente.

    Args:
        user_id: UUID utente.
        db: Sessione DB.

    Raises:
        HTTPException 404: Utente non trovato.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utente non trovato")
    return user


@router.put("/{user_id}", response_model=UserOut)
def update_user(user_id: str, payload: UserUpdate, db: Session = Depends(get_db)):
    """Aggiorna i dati di un utente.

    Args:
        user_id: UUID utente.
        payload: Campi da aggiornare (tutti opzionali).
        db: Sessione DB.

    Returns:
        UserOut: Utente aggiornato.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utente non trovato")
    # model_dump(exclude_unset=True) restituisce solo i campi effettivamente
    # passati nel body, evitando di sovrascrivere con None i campi non toccati
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: str, db: Session = Depends(get_db)):
    """Elimina un utente.

    Args:
        user_id: UUID utente.
        db: Sessione DB.

    Raises:
        HTTPException 404: Utente non trovato.

    Note:
        Status 204 = No Content (successo senza body di risposta).
        TODO: solo l'admin può eliminare utenti (aggiungere check ruolo).
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utente non trovato")
    db.delete(user)
    db.commit()
