# 🗄️ Database

## Panoramica

GateKeeper utilizza un database **NoSQL basato su file JSON**. Questa scelta è stata fatta per:

- **Semplicità**: nessuna dipendenza da database esterni
- **Portabilità**: il database è un singolo file, facilmente trasportabile e versionabile
- **Zero configurazione**: non richiede server DB, installazione o migrazioni
- **Resilienza**: ideale per ambienti embedded come Raspberry Pi

> Il progetto è stato inizialmente prototipato con SQLite, ma è stato migrato a un archivio documentale JSON per semplificare il deployment e lo sviluppo.

## File di Database

Il database è salvato in:
```
backend/app/db/nosql_db.json
```

## Collezioni

| Collezione | Descrizione |
|---|---|
| `users` | Utenti del sistema (admin, adulti, bambini) |
| `devices` | Dispositivi/oggetti con tag RFID associati |
| `user_devices` | Associazioni molti-a-molti tra utenti e dispositivi |
| `logs` | Storico entrate/uscite con timestamp |
| `events` | Eventi di sistema (passaggi, alert, eventi di sistema) |

## Thread Safety

L'accesso al file JSON è gestito in modo thread-safe:

- **`threading.RLock`** per sincronizzare letture e scritture concorrenti
- **Scritture atomiche** tramite file temporaneo (`.tmp`) + `os.replace()`
- Previene corruzione dei dati in caso di crash durante la scrittura

## Struttura di un Record

```json
// Esempio: utente
{
    "id": 1,
    "email": "mario.rossi@local.invalid",
    "hash_psw": "scrypt:...",
    "username": "mario",
    "role": "adult",
    "uuid": "550e8400-e29b-41d4-a716-446655440000",
    "is_active": true,
    "last_seen_at": null,
    "current_location": "unknown",
    "created_at": "2026-04-28T10:30:00Z"
}
```

```json
// Esempio: dispositivo
{
    "id": 1,
    "name": "Ombrello",
    "rfid_tag": "RFID-a1b2c3d4e5f6",
    "category": "accessory",
    "is_essential": false,
    "alert_rules": "{}",
    "current_status": "inside",
    "created_at": "2026-04-28T10:30:00Z"
}
```

## Gestione degli ID

- ID **auto-incrementanti** per ogni collezione
- Gestiti tramite oggetto `next_ids` nel file JSON
- Unicità garantita dal lock thread-safe

## Schema delle Entità

### Utente (`users`)
| Campo | Tipo | Descrizione |
|---|---|---|
| id | int | Identificatore univoco |
| email | string | Email (auto-generata se non specificata) |
| hash_psw | string | Hash password (Werkzeug) |
| username | string | Nome utente (univoco) |
| role | enum | `admin`, `adult`, `child` |
| uuid | string | UUID (auto-generato se non specificato) |
| is_active | bool | Se l'utente è attivo |
| last_seen_at | string/null | Ultimo rilevamento |
| current_location | enum | `inside`, `outside`, `unknown` |
| created_at | string | Timestamp ISO 8601 |

### Dispositivo (`devices`)
| Campo | Tipo | Descrizione |
|---|---|---|
| id | int | Identificatore univoco |
| name | string | Nome del dispositivo |
| rfid_tag | string | Tag RFID (univoco, auto-generato se non specificato) |
| category | string | Categoria (es. `accessory`, `electronics`) |
| is_essential | bool | Se è un oggetto essenziale |
| alert_rules | string | Regole di notifica (JSON) |
| current_status | enum | `inside`, `outside`, `unknown` |
| created_at | string | Timestamp ISO 8601 |

## Layer Software

```
endpoint.py          (API REST → chiama models.py)
    ↓
models.py            (CRUD + validazione)
    ↓
storage.py           (I/O file JSON + thread safety)
    ↓
nosql_db.json        (Persistenza su disco)
```

## Evoluzione Futura

- L'architettura attuale supporta una futura migrazione a **PostgreSQL**
- Il layer `models.py` può essere sostituito con SQLAlchemy senza modificare gli endpoint
- Per deploy più robusti si prevede l'uso di un database esterno
