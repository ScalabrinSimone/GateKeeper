"""
GateKeeper – Backend principale
================================
Entrypoint dell'applicazione FastAPI.

Come funziona il ciclo di vita:
  1. All'avvio (lifespan) il database viene inizializzato (tabelle create)
  2. FastAPI registra tutti i router (auth, users, objects, events)
  3. Uvicorn serve le richieste HTTP

Avvio in sviluppo:
  uvicorn main:app --reload --host 0.0.0.0 --port 8000

Avvio su Raspberry Pi (produzione):
  uvicorn main:app --host 0.0.0.0 --port 8000
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import init_db
from routers import auth, users, objects, events


# ── Lifespan ──────────────────────────────────────────────────────────────────
# Il lifespan sostituisce i vecchi @app.on_event("startup").
# Tutto prima del `yield` viene eseguito all'avvio,
# tutto dopo al termine dell'applicazione.
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Crea le tabelle nel DB se non esistono ancora
    init_db()
    # TODO: avvia qui il BLE scanner (thread separato)
    # TODO: avvia qui la connessione al reader RFID UHF
    yield
    # TODO: cleanup risorse (chiudi connessioni hardware)


# ── Applicazione FastAPI ──────────────────────────────────────────────────────
app = FastAPI(
    title="GateKeeper API",
    description="Backend IoT per il sistema GateKeeper – RFID + BLE tracking",
    version="0.1.0",
    lifespan=lifespan,
    # In produzione imposta docs_url=None per non esporre Swagger pubblicamente
    docs_url="/docs",
    redoc_url="/redoc",
)


# ── CORS ──────────────────────────────────────────────────────────────────────
# CORS (Cross-Origin Resource Sharing): permette all'app Flutter Web e a
# qualsiasi client di fare richieste all'API.
# In produzione, sostituisci ["*"] con il dominio reale del tunnel Cloudflare.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,  # es. ["https://gatekeeper.tuodominio.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Registrazione router ──────────────────────────────────────────────────────
# Ogni router gestisce un gruppo di endpoint correlati.
# Il prefisso viene aggiunto automaticamente a tutti i path del router.
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(objects.router, prefix="/api/v1/objects", tags=["objects"])
app.include_router(events.router, prefix="/api/v1/events", tags=["events"])


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["system"])
def health_check():
    """Endpoint usato dall'app Flutter per verificare se il Raspberry è raggiungibile."""
    return {"status": "ok", "version": "0.1.0"}
