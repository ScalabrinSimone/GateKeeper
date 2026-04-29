"""
core/security.py — Funzioni JWT e password hashing.

Questa è la "cassaforte" della sicurezza.
Contenuto:
- CryptContext per hash/verify password con bcrypt
- create_access_token() per generare JWT
- decode_access_token() per verificare e leggere JWT

Bcrypt: algoritmo di hashing lento e sicuro per le password.
        "Lento" è intenzionale: rallenta i brute-force attack.

JWT (JSON Web Token): stringa firmata che contiene dati utente (es. user_id).
        Il client la invia in ogni richiesta nell'header Authorization.
        Il server la verifica con SECRET_KEY senza bisogno di consultare il DB.
"""

from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from config import settings

# CryptContext configura passlib per usare bcrypt come algoritmo di hashing.
# deprecated="auto" aggiorna automaticamente gli hash vecchi al prossimo login.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain_password: str) -> str:
    """
    Genera l'hash bcrypt di una password in chiaro.

    Args:
        plain_password: Password digitata dall'utente.

    Returns:
        Stringa hash da salvare nel DB.

    Esempio:
        hashed = hash_password("miapassword")
        # hashed = "$2b$12$..."
    """
    return pwd_context.hash(plain_password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verifica che una password in chiaro corrisponda all'hash salvato.

    Args:
        plain_password:   Password digitata dall'utente al login.
        hashed_password:  Hash salvato nel DB.

    Returns:
        True se la password è corretta, False altrimenti.
    """
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: str | Any, expires_delta: timedelta | None = None) -> str:
    """
    Crea un JWT firmato con SECRET_KEY.

    Args:
        subject:       Contenuto del claim "sub" (di solito l'email o l'id utente).
        expires_delta: Durata del token. Se None usa ACCESS_TOKEN_EXPIRE_MINUTES.

    Returns:
        Stringa JWT (es. "eyJhbGci...")

    Il payload contiene:
        sub: subject (identifica l'utente)
        exp: expiry timestamp (il token scade a quest'ora)
    """
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload = {"sub": str(subject), "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> str | None:
    """
    Decodifica e verifica un JWT.

    Args:
        token: Stringa JWT ricevuta nell'header Authorization.

    Returns:
        Il valore del claim "sub" (email/id) se il token è valido,
        None se il token è scaduto, malformato o firmato con chiave sbagliata.

    Nota: jose.JWTError copre sia token scaduti sia token falsificati.
    """
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None
