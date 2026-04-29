"""
GateKeeper – Setup database
============================
Configura SQLAlchemy e crea le tabelle al primo avvio.

SQLAlchemy funziona così:
  - `engine`: la connessione al DB (come un "driver")
  - `SessionLocal`: factory per creare sessioni (ogni richiesta HTTP ottiene la sua)
  - `Base`: classe base da cui ereditano tutti i modelli ORM
  - `get_db()`: dependency di FastAPI che inietta la sessione nei router

Schema del flusso:
  Richiesta HTTP → router → get_db() → SessionLocal() → query DB → commit/rollback → close
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from config import settings


# ── Engine ────────────────────────────────────────────────────────────────────
# connect_args={"check_same_thread": False} è necessario SOLO per SQLite
# perché SQLite di default permette l'accesso da un solo thread.
# Con PostgreSQL rimuovi questo argomento.
engine = create_engine(
    settings.database_url,
    connect_args={"check_same_thread": False} if "sqlite" in settings.database_url else {},
    # echo=True  # Decommenta per vedere tutte le query SQL eseguite (debug)
)


# ── Session factory ───────────────────────────────────────────────────────────
# autocommit=False → devi chiamare esplicitamente session.commit()
# autoflush=False  → i cambiamenti vengono scritti solo su commit
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# ── Base ORM ──────────────────────────────────────────────────────────────────
# Tutti i modelli (User, RfidObject, ecc.) ereditano da Base.
# Base.metadata.create_all(engine) crea le tabelle fisiche nel DB.
class Base(DeclarativeBase):
    pass


def init_db() -> None:
    """Crea tutte le tabelle definite nei modelli se non esistono.

    Chiamato una volta all'avvio dall'app (vedi main.py lifespan).
    In produzione con PostgreSQL, usa Alembic per le migrazioni invece di questo.
    """
    # L'import qui è necessario per far registrare i modelli su Base.metadata
    from models import user, rfid_object, gate_event, home  # noqa: F401
    Base.metadata.create_all(bind=engine)


def get_db():
    """Dependency FastAPI: fornisce una sessione DB per ogni richiesta.

    Usato come:
        def my_endpoint(db: Session = Depends(get_db)):
            ...

    Il `finally` garantisce che la sessione venga sempre chiusa,
    anche se la richiesta genera un'eccezione.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
