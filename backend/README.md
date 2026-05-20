# Backend FastAPI per dispositivi, utenti ed eventi

Questo progetto è un backend FastAPI pensato per Raspberry Pi / sistemi embedded con:

- API REST per `users`, `devices`, `user-devices`, `logs` ed `events`
- persistenza locale su file JSON (`app/db/nosql_db.json`)
- scanner BLE in background
- lettore RFID UHF in background

## Struttura del progetto

- `app/api/endpoint.py` — espone tutte le API REST
- `app/db/storage.py` — layer di persistenza JSON con lock e scrittura atomica
- `app/db/models.py` — logica applicativa e CRUD
- `app/db/init_db.py` — inizializzazione del database locale
- `app/ble/blescanner.py` — scansione BLE continua in background
- `app/rfid/rfidreader.py` — lettura RFID seriale in background
- `run_all.py` — avvio completo di database, BLE e server API

## Requisiti

- Python 3.10 o superiore
- su Linux / Raspberry Pi, accesso al dispositivo seriale del lettore RFID e al Bluetooth del sistema

## Installazione

```bash
python -m venv .venv
source .venv/bin/activate   # Linux/macOS
# oppure:
.venv\Scripts\activate      # Windows / PowerShell

pip install -r requirements.txt
```

## Inizializzazione del database

Il database viene creato automaticamente se manca, ma puoi inizializzarlo anche a mano:

```bash
python -m app.db.init_db
```

Per ricrearlo da zero:

```bash
python -m app.db.init_db --force
```

## Avvio consigliato

Per avviare tutto il progetto (database, BLE, API e RFID):

```bash
python run_all.py
```

Opzioni utili:

```bash
python run_all.py --host 0.0.0.0 --port 8000
python run_all.py --reset-db
python run_all.py --factory-reset   # svuota DB e rigenera factory_code
python run_all.py --seed-test       # crea account test/test1234 + dati demo
```

### Account di test

Per saltare il pairing in sviluppo e provare subito l'app:

```bash
python run_all.py --seed-test
```

Credenziali generate:

- username: `test`
- password: `test1234`
- ruolo: admin
- house: `Casa Demo`

### Reset di fabbrica sul Raspberry

Quando vuoi disaccoppiare l'hub da una casa direttamente sul Pi
(ad esempio se hai perso l'admin), esegui:

```bash
python scripts/factory_reset.py
```

Il comando svuota i database, rigenera un `factory_code` e lo stampa
in console. Questo codice va inserito nell'app durante il nuovo pairing.

## Avvio solo API

Se vuoi avviare solo FastAPI/Uvicorn:

```bash
uvicorn app.api.endpoint:app --host 0.0.0.0 --port 8000
```

## Endpoint principali

- `GET /` — health check
- `POST /users`, `GET /users`, `GET /users/{user_id}`, `PUT /users/{user_id}`, `DELETE /users/{user_id}`
- `GET /users/by-username/{username}`
- `POST /devices`, `GET /devices`, `GET /devices/{device_id}`, `PUT /devices/{device_id}`, `DELETE /devices/{device_id}`
- `GET /devices/by-rfid/{rfid_tag}`
- `POST /user-devices`, `GET /user-devices`, `GET /user-devices/{association_id}`, `DELETE /user-devices/{association_id}`
- `POST /logs`, `GET /logs`, `GET /logs/{log_id}`, `PUT /logs/{log_id}`, `DELETE /logs/{log_id}`
- `POST /events`, `GET /events`, `GET /events/{event_id}`, `PUT /events/{event_id}`, `DELETE /events/{event_id}`

### Endpoint aggiunti per l'app

- `GET /hub/info`, `GET /hub/status` — stato pairing
- `POST /hub/pair` — primo pairing (crea admin + marca paired)
- `POST /hub/factory-reset` — reset (solo admin Bearer token)
- `POST /auth/login`, `GET /auth/me`, `POST /auth/logout`
- `POST /auth/forgot-password`, `POST /auth/reset-password`
- `POST /invites`, `GET /invites`, `GET /invites/by-token/{token}`,
  `POST /invites/accept`, `DELETE /invites/{id}`

### Discovery LAN (UDP)

L'hub risponde a broadcast UDP `GATEKEEPER_DISCOVER?` sulla porta 51820,
così l'app Flutter può scoprire automaticamente l'IP del Raspberry.

## Note operative

- Lo scanner BLE gira in un thread separato e stampa i dispositivi rilevati nel terminale.
- Il lettore RFID parte all'avvio dell'app FastAPI e si ferma allo shutdown.
- I record vengono salvati in un JSON locale, non in SQLite.

## Test rapidi

Sono presenti anche script di supporto in `scripts/` per l'avvio e per richieste di test.
