# GateKeeper App (Flutter)

App Flutter per il sistema IoT domestico GateKeeper.
È la parte client del sistema (Raspberry Pi + RFID + BLE + FastAPI backend).
Questa cartella è l'**unico scope di scrittura primaria** del progetto, come
da istruzioni in `.github/instructions/GateKeeperIstruzioniProgetto.instructions.md`.

## 1. Architettura

L'app è strutturata in modo modulare ma volutamente semplice: niente DI pesante,
niente state management complesso. Le scelte privilegiano leggibilità ed
"effetto educativo" per chi vuole imparare Flutter dal codice.

- UI: Material 3 con tema chiaro/scuro custom (palette GateKeeper).
- Stato globale: un solo `ChangeNotifier` (`SettingsController`) per tema +
  lingua, persistito con `shared_preferences`.
- Stato locale: ogni pagina gestisce il proprio stato con `setState`.
- Routing: `go_router` con `StatefulShellRoute.indexedStack` per tab persistenti.
- Localizzazione: i `.arb` ufficiali in `lib/l10n/` + una classe runtime
  `AppL10n` (mappa interna allineata agli `.arb`) per evitare di rigenerare
  `app_localizations.dart` durante lo sviluppo. Lingua di default: italiano.
- Dati: mock in `lib/shared/data/mock_data.dart`. Sono **chiaramente separati**
  da qualsiasi service futuro (vedi sezione Backend).

## 2. Struttura cartelle

```
lib/
  main.dart                 // bootstrap, carica SettingsController e avvia l'app
  app.dart                  // MaterialApp.router, ascolta SettingsController
  router/
    app_router.dart         // configurazione go_router (StatefulShellRoute)
  core/
    theme/
      app_colors.dart       // palette ufficiale + alias semantici
      app_theme.dart        // ThemeData dark/light Material 3
    state/
      settings_controller.dart  // tema + lingua, persistenza prefs
    i18n/
      app_l10n.dart         // mappa di traduzioni + delegate Localizations
  l10n/
    app_it.arb              // sorgente IT
    app_en.arb              // sorgente EN
  shared/
    models/                 // AppUser, SmartObject, GateEvent, enums
    data/mock_data.dart     // dati di esempio
    widgets/                // AppShell, GKCard, GKButton, StatusPill, ...
  features/
    dashboard/              // pagina dashboard (status bento + eventi live)
    objects/                // griglia oggetti smart
    events/                 // cronologia con filtri
    members/                // membri del nucleo familiare
    notifications/          // centro notifiche critiche
    settings/               // 4 sezioni di impostazioni
    account/                // profilo utente
test/
  widget_test.dart          // smoke test dell'app
```

## 3. Routing

`AppRouter.build(settings: ...)` espone un `StatefulShellRoute.indexedStack`
con 7 branch (uno per sezione + account). Lo shell è `AppShell` (sidebar
desktop + header con quick actions + bottom nav su mobile). Vantaggi di
`StatefulShellRoute`:

- ogni tab mantiene il proprio stato (scroll, filtri, ecc.) durante la
  navigazione,
- l'indice corrente è esposto a `AppShell` per evidenziare la voce attiva
  nella sidebar e nel bottom bar.

Route principali:

| Path             | Descrizione              |
|------------------|--------------------------|
| `/dashboard`     | Panoramica stato casa    |
| `/objects`       | Oggetti smart taggati    |
| `/events`        | Cronologia eventi        |
| `/members`       | Membri famiglia          |
| `/notifications` | Notifiche critiche       |
| `/settings`      | Configurazione hub/app   |
| `/account`       | Profilo utente           |

## 4. Stato

`SettingsController` (`core/state/settings_controller.dart`) è un
`ChangeNotifier` minimale:

- carica preferenze persistite (tema + lingua) all'avvio,
- notifica i listener al cambio,
- `GateKeeperApp` (in `app.dart`) ascolta e ricostruisce `MaterialApp.router`.

Per il resto, ogni pagina gestisce il proprio stato locale con `setState`.
Questa scelta è volutamente semplice perché:

- riduce le dipendenze,
- è didattica (chi legge il codice capisce subito il flusso),
- l'app non ha ancora bisogno di store globali (lo si può introdurre quando
  arriva l'integrazione backend con repository e cache).

## 5. UI e regole di design

- Tema scuro come default, con tema chiaro derivato dalla stessa palette.
- Palette: Ink Black `#0D1117`, Charcoal Blue `#41474E`, Stormy Teal `#00767A`,
  Orange Gold `#FFA400`, Lavender Blush `#F0E2E7`.
- Nessun banner "app" ridondante.
- Sidebar a sinistra (desktop) con animazione sull'item selezionato,
  alert + account in fondo a sinistra.
- Bottom nav (mobile) con stessa selezione animata.
- Componenti chiave riusabili: `GKCard`, `GKButton`, `StatusPill`,
  `SectionHeader`, `GKLogo`.
- Animazioni fluide: `AnimatedContainer`, `AnimatedSwitcher`,
  `AnimatedOpacity`, `AnimatedScale`, transizioni di pagina
  `FadeForwardsPageTransitionsBuilder`.
- Haptic feedback su sidebar/bottombar/lingua/tema (utile soprattutto mobile).

## 6. Localizzazione

I file `.arb` (`app_it.arb`, `app_en.arb`) restano la sorgente di verità.
Per non dipendere dalla rigenerazione del codice da `flutter gen-l10n`
durante lo sviluppo, è presente anche `AppL10n` (in `core/i18n/app_l10n.dart`)
con la stessa mappa di chiavi.

- Lingua di default: italiano (`Locale('it')`).
- Toggle nell'header (IT/EN) e in Impostazioni.
- Persistenza tramite `SharedPreferences`.

## 7. Modelli e mock

In `shared/models/` i modelli rispecchiano i campi del backend FastAPI
documentati nelle istruzioni di progetto, così la mappatura futura su DTO
risulta 1:1:

- `AppUser` ← `users` (role, is_active, last_seen_at, current_location).
- `SmartObject` ← `devices` (rfid_tag, category, is_essential,
  current_status).
- `GateEvent` ← `events` (event_type, direction, detected_objects,
  detected_users).

I dati di esempio in `shared/data/mock_data.dart` simulano una famiglia di
4 membri, 5 oggetti smart e una manciata di eventi (alcuni risolti, alcuni
critici).

## 8. Integrazione backend

L'app è collegata al backend FastAPI tramite un layer dedicato in
`lib/data/`. Le pagine non chiamano mai HTTP direttamente: passano sempre
da repository / API client.

### 8.1 Layer dati

```
lib/data/
  api/
    api_client.dart          // HTTP client con bearer token e timeout
    api_exception.dart       // errore tipato (statusCode, isUnauthorized, ...)
    dto.dart                 // DTO 1:1 col backend
    auth_api.dart            // /auth/login, /auth/me, /auth/forgot-password, ...
    hub_api.dart             // /hub/info, /hub/pair, /hub/factory-reset
    users_api.dart           // /users CRUD
    devices_api.dart         // /devices CRUD
    events_api.dart          // /events
    logs_api.dart            // /logs
    invites_api.dart         // /invites e accept
  gatekeeper_api.dart        // facade singleton con tutti gli endpoint
  services/
    discovery_service.dart   // UDP broadcast per trovare il Pi in LAN
  repositories/
    repositories.dart        // DTO -> modelli di dominio (AppUser, ...)
```

### 8.2 Configurazione URL

`core/config/api_config.dart` mantiene la base URL persistita. All'avvio:

1. `ApiConfig.load()` legge l'ultima base URL salvata,
2. l'utente può cambiarla manualmente o, meglio, scoprirla via
   `DiscoveryService.discover()` durante il pairing.

### 8.3 Sessione e auth

`core/state/auth_controller.dart` (`AuthController`) è il `ChangeNotifier`
che governa la sessione:

| Stage             | UI mostrata                          |
|-------------------|--------------------------------------|
| `loading`         | Splash (mentre verifica token/hub)   |
| `offline`         | `pair_choice_page` (welcome)         |
| `needsPairing`    | `pair_choice_page` (welcome)         |
| `needsLogin`      | `login_page`                         |
| `authenticated`   | shell + pagine principali            |

Il token è salvato in `flutter_secure_storage` (su web fallback a
`shared_preferences`).

### 8.4 Endpoint usati

Tutti quelli base (`/users`, `/devices`, `/events`, `/logs`) **più**
quelli aggiunti al backend per supportare il flusso completo:

- `GET /hub/info` — stato pairing pubblico,
- `POST /hub/pair` — primo pairing con admin + factory code,
- `POST /hub/factory-reset` — reset di fabbrica (solo admin),
- `POST /auth/login` / `GET /auth/me` / `POST /auth/logout`,
- `POST /auth/forgot-password` / `POST /auth/reset-password`,
- `POST /invites` / `GET /invites` / `GET /invites/by-token/{t}` /
  `POST /invites/accept` / `DELETE /invites/{id}`.

## 9. Onboarding e pairing del Raspberry

Il flusso di primo avvio è disegnato come un prodotto consumer.

1. **Welcome** (`/welcome`, `PairChoicePage`): l'utente sceglie
   _Accedi_ (hub già configurato) o _Configura Raspberry_.
   Su **web** l'opzione di pairing è disabilitata (`PlatformInfo.canPairDevice`).
2. **Discovery** (`/onboarding/discover`, `DiscoveryPage`):
   `DiscoveryService` invia un broadcast UDP `GATEKEEPER_DISCOVER?` sulla
   porta 51820 e raccoglie le risposte. Ogni hub trovato è mostrato come
   tile: tappando si salva la base URL e si passa allo step successivo.
   È sempre disponibile una connessione manuale tramite URL.
3. **Setup wizard** (`/onboarding/setup`, `SetupWizardPage`):
   - Step 0: introduzione (cosa fa GateKeeper, in 3 punti),
   - Step 1: creazione admin (`/hub/pair` con factory_code se richiesto),
   - Step 2: scelta tag essenziali (chiavi/portafoglio/ecc.),
     create con `POST /devices`,
   - Step 3: generazione inviti (`POST /invites`) per i membri,
     condivisibili tramite copia/incolla,
   - Step 4: conferma e ingresso in app.

### 9.1 Reset/disaccoppiamento

Esistono due modi per disaccoppiare l'hub:

- **Dall'app, solo admin**: Impostazioni → _Factory reset_.
  Chiama `POST /hub/factory-reset` con `confirm=true`, che cancella tutto
  il database e rigenera un `factory_code` (mostrato in console / dal device
  fisico). L'app viene riportata su `/welcome`.
- **Direttamente sul Raspberry**: lo script
  `backend/scripts/factory_reset.py` esegue la stessa operazione localmente
  e stampa il nuovo `factory_code`.

## 10. Inviti, recupero password, notifiche

- **Inviti**: il link di un invito può essere condiviso come token testuale.
  Il destinatario apre l'app, tocca _Ho un codice di invito_, incolla il
  token e crea il proprio account. Il ruolo viene ereditato dall'invito.
  È supportato anche il deep link `/invite/:token`.
- **Recupero password**: schermata `/recover`. L'utente inserisce la mail,
  riceve un codice via SMTP (se configurato) o via file `outbox.log` (se
  no), poi imposta una nuova password.
- **Notifiche locali**: `NotificationsController` inizializza
  `flutter_local_notifications` (Android/iOS/macOS/Linux/Windows). Sul web
  resta inerte. Permette di mostrare avvisi anche con app aperta in
  background. Per il push "vero" (server → device con app chiusa) si
  potrà collegare FCM/APNs in un secondo step.

## 11. Multipiattaforma

L'app gira su Windows, macOS, Linux, Android, iOS, Web. Restrizioni:

- **Pairing**: solo PC o smartphone (richiede UDP). Sul web è disponibile
  solo il login.
- **Notifiche di sistema con app chiusa**: solo mobile.
- **Storage sicuro del token**: nativo via `flutter_secure_storage`, su
  web fallback a `shared_preferences`.

## 12. Account di test

In sviluppo, è disponibile un seed per saltare il pairing:

```powershell
cd backend
python run_all.py --seed-test
```

Lo script crea automaticamente:

- admin di test: `test` / `test1234` (email `test@local.test`),
- casa "Casa Demo", dispositivi e log demo,
- un invito attivo (token stampato in console).

Una volta partito il backend, in app basta scegliere _Accedi_ e usare
queste credenziali.

## 9. Setup e avvio

Requisiti: Flutter stable >= 3.41.

```powershell
cd app
flutter pub get
flutter run -d windows   # desktop nativo
flutter run -d chrome    # browser
flutter test             # test
```

Il primo avvio web genera anche le risorse in `web/` (già committate).

## 10. Test

`test/widget_test.dart` esegue un piccolo smoke test:

- inizializza `SharedPreferences` in-memory,
- crea il `SettingsController`,
- monta la `GateKeeperApp` e verifica la presenza di "Dashboard" nella UI.

## 11. Note didattiche (per imparare Flutter da questa app)

- `StatefulShellRoute.indexedStack` mantiene un widget per ogni branch così
  lo stato (es. scroll, filtri) non si resetta cambiando tab.
- `LayoutBuilder` viene usato per le scelte tra layout desktop/mobile senza
  introdurre librerie di responsività.
- `AnimatedContainer` e `AnimatedSwitcher` sono il modo più semplice per
  ottenere animazioni fluide con poco codice.
- `MaterialApp.router` + `go_router` consentono di gestire URL profondi
  (utile soprattutto su web/desktop).
- `ChangeNotifier` + `addListener` è il pattern più leggero per uno stato
  globale "tipo Provider", senza dipendere da librerie esterne.

## 13. TODO noti

- Refresh token e revoca server-side dei token (oggi il token è solo verificato
  via HMAC + TTL).
- Push remoto vero (FCM/APNs) per notifiche con app chiusa.
- Sostituire del tutto `MockData` quando il backend è raggiungibile
  (attualmente è usato come fallback se l'API non risponde).
- Cloudflare Tunnel/Zero Trust per l'accesso remoto al Raspberry.
- Test widget per il wizard di onboarding.

## 14. Convenzioni commenti

Tutti i commenti seguono la regola del progetto: iniziano con `//` senza
spazio, terminano con un punto, sono in italiano. Esempi:

```dart
//Commento.
//TODO: collegare il backend.
//FIXME: gestire timeout di rete.
```

