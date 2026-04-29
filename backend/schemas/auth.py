"""
GateKeeper – Schema autenticazione
===================================
Definisce i tipi di input/output per gli endpoint di login e token.
"""

from pydantic import BaseModel


class LoginRequest(BaseModel):
    """Body richiesta login.

    Attributi:
        email: Email dell'utente.
        password: Password in chiaro (viene verificata contro l'hash nel DB).
    """
    email: str
    password: str


class TokenOut(BaseModel):
    """Risposta del login: restituisce il JWT all'app Flutter.

    Attributi:
        access_token: JWT da salvare nell'app e inviare come Bearer token.
        token_type: Sempre "bearer" per convenzione OAuth2.
    """
    access_token: str
    token_type: str = "bearer"
