"""
routers/ — Router FastAPI divisi per dominio.

Ogni file definisce un APIRouter con le sue route.
Vengono tutti montati in main.py con app.include_router().

Struttura:
    auth.py    — POST /api/auth/login, POST /api/auth/logout
    users.py   — CRUD utenti (solo admin)
    objects.py — CRUD oggetti RFID
    events.py  — lettura eventi + ricezione eventi dal Raspberry
"""
