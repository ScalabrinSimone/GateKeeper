"""
routers/auth.py — Endpoint di autenticazione.

Endpoint:
    POST /api/auth/login   — riceve email+password, restituisce JWT
    POST /api/auth/logout  — invalida il token (TODO: implementare blocklist)
    GET  /api/auth/me      — restituisce i dati dell'utente loggato
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.deps import get_current_user, get_db
from core.security import create_access_token, verify_password
from models.user import User
from schemas.auth import LoginRequest, TokenResponse
from schemas.user import UserRead

# prefix="/api/auth" → tutte le route qui diventano /api/auth/...
# tags=["auth"]      → raggruppamento nella doc OpenAPI (/docs)
router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Autentica un utente e restituisce un JWT.

    Flusso:
        1. Cerca l'utente per email nel DB.
        2. Verifica la password con bcrypt.
        3. Genera e restituisce un JWT.

    Raises:
        401: se email non trovata o password errata.
    """
    # Cerca utente per email
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    # Risposta generica per non rivelare se l'email esiste o no (security best practice)
    if user is None or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account disabled",
        )

    # Il subject del JWT è l'email: viene usata in get_current_user() per ritrovare l'utente
    token = create_access_token(subject=user.email)
    return TokenResponse(access_token=token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: User = Depends(get_current_user)):
    """
    Logout dell'utente.

    TODO: implementare una JWT blocklist (es. in Redis) per invalidare il token.
          Al momento il token rimane valido fino alla scadenza naturale.
          Soluzione semplice: ridurre ACCESS_TOKEN_EXPIRE_MINUTES a 15 e usare
          refresh token per rinnovarlo silenziosamente.
    """
    # Per ora non facciamo nulla lato server — il client deve eliminare il token
    return


@router.get("/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Restituisce i dati dell'utente attualmente loggato.

    Richiede header: Authorization: Bearer <token>
    """
    return current_user
