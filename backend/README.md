# GateKeeper — Backend

Backend FastAPI del sistema IoT GateKeeper. Gira sul **Raspberry Pi 4** e gestisce:
- Autenticazione JWT degli utenti
- CRUD utenti, oggetti RFID ed eventi
- Ricezione eventi dal modulo RFID/BLE
- Esposizione API all'app Flutter via Cloudflare Tunnel

---

## Avvio rapido

```bash
# 1. Vai nella cartella backend
cd backend

# 2. Crea e attiva il virtualenv
python -m venv .venv
source .venv/bin/activate        # Linux/macOS
# .venv\Scripts\activate          # Windows

# 3. Installa le dipendenze
pip install -r requirements.txt

# 4. Copia il file di configurazione e modifica i valori
cp .env.example .env
# Apri .env e imposta SECRET_KEY con: openssl rand -hex 32

# 5. Avvia il server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Documentazione API interattiva: **http://localhost:8000/docs**

---

## Struttura

```
backend/
├── main.py              # Entrypoint FastAPI
├── config.py            # Settings da .env (pydantic-settings)
├── database.py          # SQLAlchemy engine + sessione
├── requirements.txt
├── .env.example         # Template variabili d'ambiente
├── models/
│   ├── user.py           # ORM: tabella users
│   ├── rfid_object.py    # ORM: tabella rfid_objects
│   └── event.py          # ORM: tabella events
├── schemas/
│   ├── user.py           # Pydantic: UserCreate, UserRead, UserUpdate
│   ├── rfid_object.py    # Pydantic: RfidObjectCreate, RfidObjectRead
│   ├── event.py          # Pydantic: EventCreate, EventRead
│   └── auth.py           # Pydantic: LoginRequest, TokenResponse
├── routers/
│   ├── auth.py           # POST /api/auth/login, /logout, GET /me
│   ├── users.py          # CRUD /api/users (admin only)
│   ├── objects.py        # CRUD /api/objects
│   └── events.py         # GET/POST /api/events
└── core/
    ├── security.py       # JWT encode/decode, bcrypt hash/verify
    └── deps.py           # Dependency injection: get_db, get_current_user
```

---

## Endpoints principali

| Metodo | Path | Auth | Descrizione |
|--------|------|------|-------------|
| POST | `/api/auth/login` | No | Login → JWT |
| GET | `/api/auth/me` | JWT | Profilo utente loggato |
| GET | `/api/users/` | Admin | Lista utenti |
| POST | `/api/users/` | Admin | Crea utente |
| GET | `/api/objects/` | JWT | Lista oggetti RFID |
| POST | `/api/objects/` | Admin | Registra oggetto |
| GET | `/api/events/` | JWT | Lista eventi (paginata) |
| POST | `/api/events/` | No\* | Evento dal Raspberry |
| GET | `/health` | No | Health check |

\* Il POST /api/events è aperto sulla LAN interna. Da proteggere con X-Device-Key in produzione.

---

## Variabili d'ambiente (`.env`)

| Variabile | Default | Descrizione |
|-----------|---------|-------------|
| `DATABASE_URL` | `sqlite+aiosqlite:///./gatekeeper.db` | Connessione DB |
| `SECRET_KEY` | *(da impostare!)* | Chiave firma JWT |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `60` | Durata token |
| `ALLOWED_ORIGINS` | `http://localhost` | CORS origins |
| `DEBUG` | `false` | Abilita log SQL e /docs |

---

## TODO principali

- [ ] Alembic migrations (sostituire `create_all` in produzione)
- [ ] JWT refresh token
- [ ] X-Device-Key per autenticare il Raspberry su POST /api/events
- [ ] Notifiche push FCM/APNs
- [ ] BLE scanner in background (asyncio task)
- [ ] RFID listener in background (asyncio task)
- [ ] Logica alert bambini (CHILD role + exit senza adulti BLE)
