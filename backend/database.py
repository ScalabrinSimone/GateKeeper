"""
database.py — Setup SQLAlchemy asincrono.

Definisce:
- engine    : connessione al DB (usa DATABASE_URL da config)
- AsyncSessionLocal : factory per creare sessioni DB
- Base      : classe base da cui ereditano tutti i modelli ORM

Flusso tipico:
    1. I modelli in models/ ereditano da Base.
    2. create_all() crea le tabelle se non esistono.
    3. get_db() (in core/deps.py) apre/chiude la sessione per ogni request.
"""

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from config import settings

# --- Engine ---
# L'engine è la connessione "bassa" al database.
# echo=True stampa tutte le query SQL nel terminale (utile in DEBUG, da disabilitare in prod).
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    # connect_args solo per SQLite: disabilita il check del thread
    # (necessario perché SQLite di default non è thread-safe)
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {},
)

# --- Session factory ---
# AsyncSessionLocal è una "fabbrica" di sessioni.
# expire_on_commit=False: i modelli restano usabili dopo il commit
# (importante nelle API async dove la risposta viene costruita dopo il commit)
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# --- Base ORM ---
class Base(DeclarativeBase):
    """
    Classe base per tutti i modelli SQLAlchemy.

    Ogni modello in models/ eredita da questa classe.
    SQLAlchemy usa Base.metadata per conoscere tutte le tabelle
    e poterle creare con create_all().
    """
    pass


async def init_db() -> None:
    """
    Crea tutte le tabelle definite nei modelli ORM se non esistono già.

    Viene chiamata all'avvio dell'app in main.py (lifespan).
    In produzione usa Alembic per le migrazioni invece di questo metodo.

    TODO: rimuovere create_all() e usare alembic upgrade head in produzione.
    """
    async with engine.begin() as conn:
        # Importa qui per essere sicuro che tutti i modelli siano registrati su Base
        from models import event, rfid_object, user  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
