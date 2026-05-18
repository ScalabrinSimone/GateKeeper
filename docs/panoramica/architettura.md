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
        D --> F[(JSON NoSQL DB)]
        D --> G[BLE Scanner]
        D --> H[RFID UHF Reader]
    end

    G -->|rileva telefoni| I[👤 Utenti]
    H -->|rileva tag| J[🏷️ Oggetti]

    I & J --> D
    D -->|notifiche| A
```

---

## Flusso di un evento tipico

```mermaid
sequenceDiagram
    actor U as Utente
    participant BLE as BLE Scanner
    participant RFID as RFID Reader
    participant API as FastAPI Backend
    participant DB as JSON NoSQL DB
    participant APP as App Flutter

    U->>BLE: si avvicina alla porta
    BLE->>API: segnale telefono rilevato
    U->>RFID: passa con oggetti taggati
    RFID->>API: lista oggetti in transito
    API->>DB: aggiorna stato utente + oggetti
    API->>APP: invia notifica contestuale
```

---

## Livelli del sistema

| Livello | Componente | Responsabilità |
|---|---|---|
| **Hardware** | RFID UHF + BLE | Rilevamento fisico eventi |
| **Hub** | Raspberry Pi 4 | Coordinamento e logica |
| **Backend** | FastAPI | API, logica eventi, DB |
| **Accesso** | Cloudflare Tunnel | Connettività remota sicura |
| **Frontend** | App Flutter | Interfaccia utente |

---

## Principi di design

- **Event-driven**: nessun polling continuo, il sistema reagisce agli eventi
- **Privacy-first**: nessun dato esce dalla rete locale, solo notifiche cifrate
- **Modulare**: ogni componente è sostituibile indipendentemente
- **Offline-resilient**: il Raspberry Pi funziona anche senza connessione remota