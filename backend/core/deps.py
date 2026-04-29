"""
core/deps.py — Dependency Injection per FastAPI.

FastAPI ha un sistema di "dipendenze" (Depends) che permette di
iniettare automaticamente oggetti nelle route functions.

Esempio di utilizzo nelle route:
    @router.get("/me")
    async def get_me(current_user: User = Depends(get_current_user)):
        return current_user

FastAPI chiamerà get_current_user() prima di eseguire get_me(),
e passerà il risultato come parametro.

Funzioni esportate:
    get_db()           — apre/chiude la sessione DB per ogni request
    get_current_user() — legge JWT e restituisce l'utente loggato
    require_admin()    — come get_current_user() ma richiede ruolo ADMIN
"""

from typing import AsyncGenerator

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import decode_access_token
from database import AsyncSessionLocal
from models.user import User, UserRole

# OAuth2PasswordBearer dice a FastAPI dove trovare il token:
# il client lo invia nell'header "Authorization: Bearer <token>"
# tokenUrl è l'endpoint di login (usato solo dalla doc OpenAPI /docs)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency che fornisce una sessione DB alle route.

    Apre la sessione all'inizio della request e la chiude (con rollback
    automatico in caso di eccezione) alla fine.

    Yields:
        AsyncSession: sessione SQLAlchemy da usare nelle query.

    Utilizzo nelle route:
        async def my_route(db: AsyncSession = Depends(get_db)):
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()  # commit automatico se nessuna eccezione
        except Exception:
            await session.rollback()  # rollback se qualcosa va storto
            raise


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Dependency che verifica il JWT e restituisce l'utente loggato.

    Raises:
        HTTPException 401: se il token è mancante, scaduto o invalido.
        HTTPException 401: se l'utente non esiste più nel DB.
        HTTPException 403: se l'utente è disattivato (is_active=False).

    Returns:
        User: oggetto ORM dell'utente autenticato.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # Decodifica il token e ottieni il subject (email)
    email = decode_access_token(token)
    if email is None:
        raise credentials_exception

    # Cerca l'utente nel DB per email
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if user is None:
        raise credentials_exception

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is disabled",
        )

    return user


async def require_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """
    Dependency che verifica che l'utente corrente sia un ADMIN.

    Raises:
        HTTPException 403: se il ruolo è ADULT o CHILD.

    Returns:
        User: l'utente admin autenticato.

    Utilizzo:
        async def admin_only_route(admin: User = Depends(require_admin)):
    """
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required",
        )
    return current_user
