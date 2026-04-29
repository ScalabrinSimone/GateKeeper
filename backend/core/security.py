"""
GateKeeper – Sicurezza: JWT e password hashing
================================================
Questo modulo gestisce:
  1. Hashing e verifica delle password (bcrypt via passlib)
  2. Creazione e decodifica dei JWT (python-jose)

Come funziona il flusso di autenticazione:
  1. L'utente invia email+password al POST /api/v1/auth/login
  2. Il router verifica la password con verify_password()
  3. Se corretta, crea un JWT con create_access_token()
  4. Il JWT viene restituito all'app Flutter
  5. Per ogni richiesta successiva, l'app invia il JWT nell'header:
       Authorization: Bearer <token>
  6. Il router protetto chiama get_current_user() che decodifica il token
     e restituisce l'utente corrispondente
"""

from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from config import settings


# ── Password hashing ──────────────────────────────────────────────────────────
# bcrypt è l'algoritmo raccomandato per l'hashing delle password:
# è lento per design (rallenta gli attacchi brute-force) e usa un salt automatico.
# deprecated="auto" aggiorna automaticamente gli hash vecchi al login.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Calcola l'hash bcrypt di una password in chiaro.

    Args:
        password: Password in chiaro da hashare.

    Returns:
        Stringa hash bcrypt da salvare nel database.
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica se una password in chiaro corrisponde all'hash salvato.

    Args:
        plain_password: Password inserita dall'utente nel form di login.
        hashed_password: Hash bcrypt salvato nel database.

    Returns:
        True se la password è corretta, False altrimenti.
    """
    return pwd_context.verify(plain_password, hashed_password)


# ── JWT ───────────────────────────────────────────────────────────────────────
def create_access_token(data: dict) -> str:
    """Crea un JWT firmato con la secret key.

    Args:
        data: Payload da codificare nel token.
            Tipicamente: {"sub": user_id, "role": user_role, "home_id": home_id}

    Returns:
        Stringa JWT da restituire al client.

    Note:
        Il token scade dopo ACCESS_TOKEN_EXPIRE_MINUTES minuti (da config).
        "sub" (subject) è il campo standard JWT per identificare l'utente.
    """
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    to_encode["exp"] = expire
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def decode_access_token(token: str) -> dict | None:
    """Decodifica e verifica un JWT.

    Args:
        token: Stringa JWT da decodificare.

    Returns:
        Payload del token come dict, oppure None se il token non è valido
        o è scaduto.
    """
    try:
        return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
    except JWTError:
        # Il token è malformato, scaduto o la firma non è valida
        return None
