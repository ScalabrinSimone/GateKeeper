# ⚙️ Backend

## Panoramica

Il backend di GateKeeper è un'API REST sviluppata con **FastAPI** (Python 3.11+), progettata per gestire utenti, dispositivi, log ed eventi del sistema IoT.

## Struttura del Progetto

```
backend/
├── run_all.py                  # Entry point: avvia DB, BLE e server
├── requirements.txt            # Dipendenze Python
├── scripts/
│   ├── init_and_run.ps1        # Script setup PowerShell
│   ├── init_and_run.sh         # Script setup Bash
│   ├── test_requests.ps1       # Test HTTP PowerShell
│   └── test_requests.sh        # Test HTTP Bash
└── app/
    ├── api/
    │   └── endpoint.py         # Tutti gli endpoint REST + thread RFID
    ├── db/
    │   ├── storage.py          # Persistenza JSON thread-safe
    │   ├── models.py           # CRUD applicativi e validazione
    │   ├── init_db.py          # Inizializzazione database
    │   └── nosql_db.json       # Archivio JSON
    ├── rfid/
    │   ├── rfidreader.py       # Lettore RFID UHF seriale
    │   └── portfinder.py       # Auto-rilevamento porta seriale
    └── ble/
        └── blescanner.py       # Scanner BLE continuo
```

## Avvio

```bash
cd backend
python run_all.py --host 0.0.0.0 --port 8000
```

Per resettare il database all'avvio:
```bash
python run_all.py --host 0.0.0.0 --port 8000 --reset-db
```

## Endpoint API

Tutti gli endpoint accettano e restituiscono JSON. Versione API: `2.0.0`.

### Health Check

| Metodo | Path | Descrizione |
|---|---|---|
| `GET` | `/` | Health check del server |

### Utenti

| Metodo | Path | Descrizione |
|---|---|---|
| `POST` | `/users` | Crea un nuovo utente |
| `GET` | `/users` | Lista utenti (filtri: role, is_active, current_location) |
| `GET` | `/users/{user_id}` | Dettaglio utente per ID |
| `GET` | `/users/by-username/{username}` | Ricerca utente per username |
| `PUT` | `/users/{user_id}` | Aggiorna un utente |
| `DELETE` | `/users/{user_id}` | Elimina un utente (cascade) |

### Dispositivi

| Metodo | Path | Descrizione |
|---|---|---|
| `POST` | `/devices` | Crea un dispositivo |
| `GET` | `/devices` | Lista dispositivi (filtri: category, current_status, is_essential) |
| `GET` | `/devices/{device_id}` | Dettaglio dispositivo per ID |
| `GET` | `/devices/by-rfid/{rfid_tag}` | Ricerca dispositivo per tag RFID |
| `PUT` | `/devices/{device_id}` | Aggiorna un dispositivo |
| `DELETE` | `/devices/{device_id}` | Elimina un dispositivo (cascade) |

### Associazioni Utente-Dispositivo

| Metodo | Path | Descrizione |
|---|---|---|
| `POST` | `/user-devices` | Associa un utente a un dispositivo |
| `GET` | `/user-devices` | Lista associazioni (filtri: user_id, device_id) |
| `GET` | `/user-devices/{association_id}` | Dettaglio associazione |
| `DELETE` | `/user-devices/{association_id}` | Rimuove associazione |

### Log (entrate/uscite)

| Metodo | Path | Descrizione |
|---|---|---|
| `POST` | `/logs` | Crea un log di transito |
| `GET` | `/logs` | Lista log (filtri: user_id, device_id, action) |
| `GET` | `/logs/{log_id}` | Dettaglio log |
| `PUT` | `/logs/{log_id}` | Aggiorna un log |
| `DELETE` | `/logs/{log_id}` | Elimina un log |

### Eventi di Sistema

| Metodo | Path | Descrizione |
|---|---|---|
| `POST` | `/events` | Crea un evento |
| `GET` | `/events` | Lista eventi (filtri: user_id, event_type) |
| `GET` | `/events/{event_id}` | Dettaglio evento |
| `PUT` | `/events/{event_id}` | Aggiorna un evento |
| `DELETE` | `/events/{event_id}` | Elimina un evento |

## Thread Hardware

Il backend gestisce due thread hardware in background:

### RFID UHF Reader
- Avviato automaticamente all'avvio del server FastAPI (hook `startup`)
- Funziona in un thread `daemon` separato
- Legge tag RFID UHF sulla porta seriale
- Notifica gli eventi al sistema tramite callback `on_tag()`

### BLE Scanner
- Avviato da `run_all.py` prima del server
- Funziona in un thread `daemon` separato
- Scansiona dispositivi BLE nelle vicinanze
- Classifica euristicamente i dispositivi rilevati (telefoni vs altri)

## Stack Tecnologico

| Componente | Tecnologia |
|---|---|
| Framework | FastAPI 0.136.1 |
| Server ASGI | Uvicorn 0.46.0 |
| Runtime | Python 3.11+ |
| Persistenza | JSON file (NoSQL) |
| Hash password | Werkzeug 3.1.8 |
| RFID | pyserial 3.5 |
| BLE | bleak 3.0.2 |
| Validazione | Pydantic 2.13.4 |

## Stato Attuale

- ✅ CRUD completi per tutte le entità
- ✅ Integrazione RFID UHF funzionante
- ✅ Integrazione BLE funzionante
- ✅ Persistenza JSON thread-safe
- ⏳ **Autenticazione non ancora implementata**
- ⏳ Password hashate ma mai verificate
- ⏳ App Flutter collegata a dati mock
