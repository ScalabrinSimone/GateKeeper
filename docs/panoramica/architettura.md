# 🏗️ Architettura

## Visione generale

GateKeeper è strutturato attorno a un **hub centrale** (Raspberry Pi 4)
che coordina sensori hardware, logica applicativa e comunicazione con l'app utente.
Tutti i componenti comunicano attraverso API interne, senza esporre direttamente
nessun servizio su Internet.

---

## Schema architetturale

```mermaid
graph TD
    A[📱 App Flutter] -->|HTTPS| B[🌐 Cloudflare Tunnel]
    B --> C[🧠 Raspberry Pi 4]

    subgraph HUB ["🧠 Raspberry Pi 4 — Hub centrale"]
        C --> D[FastAPI Server]
        D --> E[Event Engine]
        D --> F[Database]
        E --> G[BLE Scanner]
        E --> H[RFID UHF Reader]
    end

    G -->|rileva telefoni| I[👤 Utenti]
    H -->|rileva tag| J[🏷️ Oggetti]

    I & J --> E
    E -->|notifiche| A
```

---

## Flusso di un evento tipico

```mermaid
sequenceDiagram
    actor U as Utente
    participant BLE as BLE Scanner
    participant RFID as RFID Reader
    participant EE as Event Engine
    participant DB as Database
    participant APP as App Flutter

    U->>BLE: si avvicina alla porta
    BLE->>EE: segnale telefono rilevato
    U->>RFID: passa con oggetti taggati
    RFID->>EE: lista oggetti in transito
    EE->>DB: aggiorna stato utente + oggetti
    EE->>APP: invia notifica contestuale
```

---

## Livelli del sistema

| Livello | Componente | Responsabilità |
|---|---|---|
| **Hardware** | RFID UHF + BLE | Rilevamento fisico eventi |
| **Hub** | Raspberry Pi 4 | Coordinamento e logica |
| **Backend** | FastAPI | API, autenticazione, DB |
| **Accesso** | Cloudflare Tunnel | Connettività remota sicura |
| **Frontend** | App Flutter | Interfaccia utente |

---

## Principi di design

- **Event-driven**: nessun polling continuo, il sistema reagisce agli eventi
- **Privacy-first**: nessun dato esce dalla rete locale, solo notifiche cifrate
- **Modulare**: ogni componente è sostituibile indipendentemente
- **Offline-resilient**: il Raspberry Pi funziona anche senza connessione remota