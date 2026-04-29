"""
GateKeeper – Router autenticazione
====================================
Endpoint per login, setup iniziale casa e refresh token.

Percorsi:
    POST /api/v1/auth/login         → login con email+password, ritorna JWT
    POST /api/v1/auth/setup         → crea la prima casa + admin (primo avvio)
    GET  /api/v1/auth/me            → restituisce l'utente corrente dal JWT
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models.user import User
from models.home import Home
from schemas.auth import LoginRequest, TokenOut
from schemas.user import UserCreate, UserOut
from core.security import hash_password, verify_password, create_access_token, decode_access_token

router = APIRouter()


# ── Dependency: utente corrente ───────────────────────────────────────────────
def get_current_user(token: str, db: Session = Depends(get_db)) -> User:
    """Dependency riutilizzabile per proteggere gli endpoint con JWT.

    Uso nei router:
        @router.get("/protected")
        def my_endpoint(current_user: User = Depends(get_current_user)):
            ...

    Args:
        token: JWT estratto dall'header Authorization: Bearer <token>.
        db: Sessione database iniettata da FastAPI.

    Raises:
        HTTPException 401: Token mancante, non valido o utente non trovato.
    """
    # TODO: estrarre il token dall'header HTTP con OAuth2PasswordBearer
    # from fastapi.security import OAuth2PasswordBearer
    # oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token non valido o scaduto",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id: str = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Utente non trovato o disabilitato")
    return user


@router.post("/login", response_model=TokenOut)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Login utente con email e password.

    Args:
        request: Body con email e password.
        db: Sessione DB.

    Returns:
        TokenOut: JWT da salvare nell'app Flutter.

    Raises:
        HTTPException 401: Credenziali non valide.
    """
    # Cerca l'utente per email
    user = db.query(User).filter(User.email == request.email).first()
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o password non corretti",
        )
    # Crea il JWT con id, ruolo e home nel payload
    token = create_access_token({
        "sub": user.id,
        "role": user.role,
        "home_id": user.home_id,
    })
    return TokenOut(access_token=token)


@router.post("/setup", response_model=UserOut, status_code=201)
def setup_home(payload: UserCreate, db: Session = Depends(get_db)):
    """Setup iniziale: crea la prima casa e l'utente admin.

    Chiamato dall'app Flutter durante il primo avvio (SetupScreen).
    Può essere eseguito solo se non esistono ancora case nel database.

    Args:
        payload: Dati del primo utente admin + nome casa (da UserCreate).
        db: Sessione DB.

    Returns:
        UserOut: L'utente admin appena creato.

    Raises:
        HTTPException 400: Setup già completato (esiste già una casa).
    """
    # Impedisce di riconfigurare se il sistema è già stato inizializzato
    if db.query(Home).count() > 0:
        raise HTTPException(
            status_code=400,
            detail="Setup già completato. Usa il codice di invito per aggiungere utenti."
        )

    # TODO: ricevere anche il nome della casa nel payload
    # Per ora usa un nome default
    home = Home(name="Casa GateKeeper")
    db.add(home)
    db.flush()  # flush assegna l'id a home senza ancora committare

    user = User(
        home_id=home.id,
        username=payload.username,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        role="admin",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
