"""
main.py — Entrypoint dell'applicazione FastAPI GateKeeper.

Qui vengono configurati:
- Il ciclo di vita dell'app (avvio/spegnimento) tramite @asynccontextmanager
- I middleware CORS (Cross-Origin Resource Sharing)
- Il montaggio di tutti i router
- L'endpoint di health check

Per avviare il server in sviluppo:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

Documentazione interattiva disponibile su:
    http://localhost:8000/docs      (Swagger UI)
    http://localhost:8000/redoc     (ReDoc)
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import init_db
from routers import auth, events, objects, users


# ---------------------------------------------------------------------------
# Lifespan: codice eseguito all'avvio e allo spegnimento del server
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gestisce il ciclo di vita dell'app.

    Il codice prima del 'yield' viene eseguito all'avvio.
    Il codice dopo il 'yield' viene eseguito allo spegnimento.

    All'avvio:
        - Crea le tabelle nel DB se non esistono.
          (in produzione usa 'alembic upgrade head' invece)
    """
    # --- Startup ---
    await init_db()  # crea tabelle se non esistono
    # TODO: avviare il BLE scanner in background
    # TODO: avviare il listener RFID in background
    yield
    # --- Shutdown ---
    # TODO: terminare i task in background in modo pulito


# ---------------------------------------------------------------------------
# Creazione app
# ---------------------------------------------------------------------------

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API backend per il sistema IoT GateKeeper — RFID + BLE door tracking.",
    lifespan=lifespan,
    # In produzione disabilita i docs per ridurre la superficie d'attacco
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)


# ---------------------------------------------------------------------------
# CORS — Cross-Origin Resource Sharing
# ---------------------------------------------------------------------------
# CORS permette all'app Flutter (su dominio diverso) di chiamare queste API.
# ALLOWED_ORIGINS è la lista di origini permesse (da .env).
# In sviluppo puoi mettere ["*"] per permettere tutto.
# In produzione metti l'URL del tunnel Cloudflare.

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],  # GET, POST, PATCH, DELETE, OPTIONS
    allow_headers=["*"],  # incluso Authorization per il JWT
)


# ---------------------------------------------------------------------------
# Router — monta tutti i gruppi di endpoint
# ---------------------------------------------------------------------------
# Ogni router gestisce un dominio (auth, users, objects, events).
# Il prefisso /api/... è definito dentro ogni router.

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(objects.router)
app.include_router(events.router)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health", tags=["system"])
async def health_check():
    """
    Endpoint di health check.

    Usato da Cloudflare Tunnel e da eventuali monitoring tools
    per verificare che il server sia vivo.

    Returns:
        dict: status e versione dell'app.
    """
    return {"status": "ok", "version": settings.APP_VERSION}
