"""
schemas/auth.py — Pydantic schemas per autenticazione JWT.
"""

from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    """
    Body POST /api/auth/login.

    Attributi:
        email: Email dell'utente.
        password: Password in chiaro (viene verificata contro l'hash nel DB).
    """

    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """
    Risposta POST /api/auth/login in caso di successo.

    Attributi:
        access_token: JWT firmato con SECRET_KEY. Includi nelle richieste
                      successive come header: Authorization: Bearer <token>
        token_type:   Sempre "bearer" (standard OAuth2).
    """

    access_token: str
    token_type: str = "bearer"
