---
description: Load this instruction for any agent working on the GateKeeper repository to provide persistent project context and guidelines at the beginning or when needed.
# applyTo: 'Describe when these instructions should be loaded by the agent based on task context' # when provided, instructions will automatically be added to the request context when the pattern matches an attached file
---

<!-- Tip: Use /create-instructions in chat to generate content with agent assistance -->

# GateKeeper — Project Instruction for Agents

Use this instruction as the persistent project context for any coding agent working on the GateKeeper repository.

## Project goal

GateKeeper is an IoT home system based on a Raspberry Pi hub, a FastAPI backend (If backend documentation is incomplete or outdated, request clarification or document assumptions explicitly), RFID detection, BLE-based user detection, and a Flutter app. The app must support home setup, users and roles, tracked objects/devices, event logs, alerts, house state, and future remote connection to the Raspberry Pi.[cite:17][cite:138]

## Mandatory repository scope

- Working branch: `feature/initializing-app`.[cite:17]
- Primary write scope: **only** `gatekeeper/app/`.[cite:16]
- `gatekeeper/backend/` is mainly **read-only** and should be analyzed to understand API contracts, models, flows, and integration points.[cite:139]
- Small backend changes are allowed **only if strictly necessary**, but backend edits are **not** the main focus and should be avoided unless they unlock app integration or fix a real blocker.[cite:139]
- If remote-access infrastructure for the Raspberry Pi is needed, a new folder may be created at the root of `gatekeeper/`, but **only if necessary** and only for the remote-access/tunnel setup. That part must also include an explanation of how it works and how to run it.[cite:138]

## Main technical target

Build a Flutter app that is:

- simple to understand,
- production-like in structure,
- efficient and maintainable,
- visually modern and coherent,
- educational for the repository owner, who wants to learn Flutter from the code and documentation.[cite:19]

Prefer simple, readable architecture over unnecessary abstraction. The app must work first, then be refined.

## Flutter constraints

The app side should use and preserve the current requested stack:

- Flutter
- `go_router`
- `flutter_svg`
- `flutter_localizations`
- `intl` with `.arb` files.[cite:17]. The applicaton needs to have italian and english translations.

Keep code modular, but do not over-engineer. Use isolates or background/concurrent work only where it is genuinely useful; do not add multithreading just for style. The backend already runs the RFID reader in the background while keeping API requests responsive, so app-side concurrency should only be introduced for real needs such as heavy parsing, processing, or long-running local tasks.[file:156]

## UI and design rules

The app is based on a Figma design (link to the design: https://www.figma.com/design/2Zrv2fRfSS4Q03uPzlnUbG/IoT?node-id=0-1&t=NYWGb2SOjEBMqXk6-1), but there is also a newer mockup generated in Google AI Studio using React code (inside the `gatekeeper/appTypescriptMockup/` folder; this folder is reference material only). Both can be used together:

- use Figma as the primary design reference when structure and design details are clear,
- use the newer Google AI Studio mockup to improve layout, spacing, hierarchy, polish, and modern UI decisions (and If you think that this layout is better than the figma one, use this),
- merge the **best aspects of both** based on UX/UI efficiency, modernity and design,
- do not blindly copy either source if it would worsen usability or Flutter architecture.

Remember that I want a modern app, with fluid animations and responisve (also with haptic feedbacks for mobile). It needs also to be performance.

UI constraints that must be preserved:

- no random “app” banner/title in the UI,[cite:18]
- modern left sidebar,
- alerts and account/profile area positioned at the bottom-left of the sidebar,[cite:18]
- smooth animation on selected sidebar item,[cite:18]
- no icon or layout overflow on resize,[cite:18]
- consistent, clean, modern look with fluid interactions.

Implement the light and dark mode (the default is dark), based on the main theme palette and create the light theme with colors based on the main one:
- Ink Black: #0D1117
- Charcoal Blue: #41474E
- Stormy Teal: #00767A
- Orange: #FFA400
- Lavander Blush: #F0E2E7

## Comment style and TODO rules

All inline comments in code must follow this exact style:

```text
//Commento.
```

Rules:

- Start with `//` immediately followed by the comment text.
- End comments with a period.
- This style must be used consistently.
- `TODO`, `FIXME`, `NOTE`, and similar markers are allowed and encouraged when useful because Todo Tree is used in VS Code.
- Write those in Italian.

Examples:

```dart
//Commento.
//TODO: sostituire il mock con il service reale.
//FIXME: gestire meglio il retry in caso di timeout.
```

## Documentation rule

Maintain or create a technical README for the Flutter app work so the repository owner can understand what was built, why it was built that way, and how the main parts work. A Flutter project already tends to include a README, but this one must be updated into a real technical reference.

The README or technical document should include:

- architecture overview,
- folder structure,
- routing overview,
- state management choice,
- service/API integration strategy,
- important models and flows,
- setup and run instructions,
- known limits / TODOs,
- explanation of any tunnel/remote-access setup if added,
- short learning-oriented notes for important Flutter concepts used.

Prefer practical, technical explanations over generic prose.[cite:19]

## Backend integration rule

The backend is not the main writing target, but it must be used as the source of truth for integration. The app should adapt to it as much as possible.[cite:139]

Known API surface from the provided endpoint documentation:

- `GET /` for server status,
- `POST/GET/GET by id/GET by username/PUT/DELETE /users`,
- `POST/GET/GET by id/GET by RFID/PUT/DELETE /devices`,
- `POST/GET/GET by id/DELETE /user-devices`,
- `POST/GET/GET by id/PUT/DELETE /logs`,
- `POST/GET/GET by id/PUT/DELETE /events`.[file:156]

Relevant backend data shapes include:

- users with `role`, `is_active`, `last_seen_at`, `current_location`,
- devices with `rfid_tag`, `category`, `is_essential`, `alert_rules`, `current_status`,
- logs with `action: ENTRATO | USCITO`,
- events with `event_type`, `direction`, `detected_objects`, and `detected_users`.[file:156]

When integrating the app:

- inspect backend code and endpoint docs first,
- build DTOs and mappers around the backend as it exists,
- avoid inventing incompatible payloads,
- isolate transport/API code from UI code,
- keep mock data clearly separated from real services,
- if a backend mismatch is found, report it clearly before changing backend code.[cite:139][file:156]

## Raspberry Pi and remote access rule

The system should be architected with future or partial support for a Raspberry Pi deployed remotely. The desired product behavior is similar to a smart-home consumer product:

- no router port-forwarding requirement,
- secure remote access,
- Raspberry Pi and app able to communicate persistently or reliably from remote contexts,
- onboarding flow where an admin can discover or associate the Raspberry when it boots,
- architecture compatible with Cloudflare Tunnel / Zero Trust-like remote access.[cite:138]

If a tunnel or remote setup is added:

- keep it isolated and well documented,
- explain what it does,
- explain how it is run,
- explain how the app is expected to discover or connect to the Raspberry,
- avoid unnecessary infrastructure if only app scaffolding is being implemented.

## Agent workflow rules

Always follow this order before making changes:

1. Summarize what you understood.
2. State the goal of the current task.
3. List the files you plan to modify.
4. Say whether backend reading is needed.
5. Only then write code.

If information is missing:

- do not invent critical backend behavior,
- do not invent routes or contracts without warning,
- ask for clarification or mark the assumption explicitly.

## Preferred implementation strategy

Use milestone-based delivery. A good order is:

1. app architecture/bootstrap,
2. routing and shell layout,
3. auth and initial flows,
4. dashboard,
5. devices/objects,
6. events/logs,
7. users/roles,
8. settings,
9. backend integration,
10. Raspberry/onboarding/remote access support,
11. cleanup and documentation.[cite:17][file:156]

## Output quality rules

Code should be:

- readable,
- simple,
- efficient,
- consistent,
- easy to learn from,
- focused on real functionality over flashy complexity.[cite:19]

Documentation should be updated together with meaningful technical changes.

Never drift outside the requested scope without stating why.

These are the main rules, now I'm gonna write the README file that we created for explaining the project in summary, so you can refer to it for a better understanding of the project and its goals:

# 🛡️ GateKeeper: Smart tag, safe exit
# 🧠 Idea generale
GateKeeper è un sistema IoT domestico intelligente che traccia in modo automatico:


chi esce ed entra di casa
quali oggetti vengono portati fuori
eventuali situazioni di rischio (dimenticanze, bambini senza supervisione, possibili furti)


Il sistema si basa su eventi (non tracking continuo) usando RFID + BLE + app + Raspberry Pi come hub centrale.


---


# 🏗️ ARCHITETTURA GENERALE
📱 Flutter App (utente)
            │
            ▼
🌐 Accesso remoto sicuro (HTTPS tunnel) │ ▼ 🧠 Raspberry Pi 4 (cuore del sistema) ┌──────────────────────────────────────────┐ │ - API server (FastAPI)                  │ │ - Database utenti e oggetti             │ │ - Event engine (logica smart home)      │ │ - BLE scanner (telefoni)                │ │ - RFID UHF reader (porta)               │ └──────────────────────────────────────────┘


---


# 🔧 COMPONENTI PRINCIPALI
🧠 Raspberry Pi 4
È il cervello del sistema.


## Funzioni:
gestione utenti
gestione oggetti
raccolta eventi
decisioni logiche
comunicazione con app


---


# 📡 Sensori porta
RFID UHF
rileva oggetti in transito
identifica passaggio (IN/OUT casa)


Esempio:
ombrello → OUT
chiavi → OUT


---


# Bluetooth Low Energy (BLE)
rileva telefoni vicini alla porta
identifica utenti presenti
aiuta associazione utente ↔ evento


---


# 📱 App (Flutter)
Funzioni:
login iniziale / setup casa
dashboard eventi
gestione utenti (admin / membri / bambini)
notifiche in tempo reale


---


# 🌐 Accesso remoto
Sistema accessibile ovunque tramite tunnel sicuro:


Cloudflare Tunnel
nessuna VPN richiesta sul telefono
Raspberry non esposto direttamente su Internet


---


# 🧠 Backend
FastAPI gestisce:


autenticazione utenti
API per app
eventi RFID/BLE
gestione dispositivi
logica smart home

## 🗄️ Database
Contiene:


utenti
dispositivi associati
oggetti RFID
eventi (entrata/uscita)
stato casa


---


# ⚙️ FUNZIONAMENTO
🚪 Uscita di casa
RFID rileva oggetti che passano
BLE rileva telefoni vicini
Raspberry associa:
utente + oggetti
aggiorna stato:
INSIDE → OUTSIDE


---


# 🏠 Rientro
RFID rileva ingresso
aggiornamento stato oggetti
notifiche app


---


# 🔔 Notifiche smart
Esempi:
“Sei uscito senza ombrello ☔” (integrazione con meteo)
“Bambino è uscito senza telefono”
“Oggetto sensibile è stato portato fuori”
"Oggetto non rientrato con il suo utente" (se un utente uscito con un oggetto rientra senza di esso)
"Possibile furto" (notifica inviata a tutta la famiglia quando un oggetto esce senza telefono con accesso all'app vicino).

Da prevedere un buzzer da suonare se si rilevano oggetti in entrata/uscita senza telefono associato nelle vicinanze, per attirare l'attenzione dell'utente.

Notifiche pernonalizzate e alcune più importanti (suono riconoscibile) per alcuni oggetti, definibili come importanti in app.


---


# 🤖 AI (opzionale)
suggerimento tag oggetti (aggiungibili in app, come stanza della casa, di chi sono, a che categoria appartengono, se sono essenziali [quindi con regole di notifica particolari], ecc...)
classificazione base immagini
riconoscimento oggetti sconosciuti


---


# 🧩 MODELLO UTENTI
👑 Admin: gestisce casa e utenti
👤 Utenti adulti: accesso completo
👶 Utenti bambini: accesso limitato


---


# 🔐 SICUREZZA
login iniziale obbligatorio
token di autenticazione (JWT) (oppure soluzioni migliori)
accesso remoto protetto
pairing dispositivo ↔ casa


---


# 💡 CONCETTO CHIAVE
GateKeeper NON è tracking continuo.


È un sistema basato su eventi:


oggetto passa dalla porta
utente è presente
sistema associa e prende decisioni


---


# 🎯 RISULTATO FINALE
GateKeeper è un sistema IoT domestico intelligente che:


traccia oggetti tramite RFID
identifica utenti tramite BLE
associa eventi in modo intelligente
invia notifiche contestuali (anche con app non accesa, usando notifiche push se l'accesso è stato effettuato dall'utente)
funziona da qualsiasi luogo
supporta multi-utente con ruoli