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

`core/config/api_config.dart` mantiene la base URL persistita. **Non c'è
più un valore di default funzionante**: l'app parte solo dopo che l'utente
ha trovato un hub via discovery (`DiscoveryService`) oppure ha inserito un
URL manuale (LAN o tunnel remoto).

1. `ApiConfig.load()` legge l'ultima base URL salvata (o `null`).
2. Se `null`, l'app forza il flow di pairing.
3. Una volta configurata, viene anche aggiunta agli "hub recenti"
   (`ApiConfig.recentHubs()`), così la schermata di discovery propone in
   testa l'URL precedente per riconnettersi con un tap.

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

## 12. Accesso remoto (Cloudflare Tunnel)

L'app è progettata per essere usata anche fuori casa, **senza port-forwarding
e senza app aggiuntive sul telefono**. La soluzione consigliata è un tunnel
HTTPS in uscita dal Raspberry (Cloudflare Tunnel, gratuito per uso
personale).

Configurazione lato Raspberry (una tantum):

1. Installa `cloudflared` sul Raspberry:
   ```bash
   sudo apt-get install -y curl
   curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
   sudo dpkg -i cloudflared.deb
   ```
2. Autenticati al tuo account Cloudflare (basta un dominio gestito su
   Cloudflare, anche gratuito):
   ```bash
   cloudflared tunnel login
   ```
3. Crea il tunnel e prendine nota dell'UUID:
   ```bash
   cloudflared tunnel create gatekeeper-home
   ```
4. Mappa l'API locale del Pi (`http://127.0.0.1:8000`) su un sottodominio:
   ```bash
   cloudflared tunnel route dns gatekeeper-home gatekeeper.example.com
   ```
5. Crea il file di configurazione `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <UUID-DEL-TUNNEL>
   credentials-file: /home/pi/.cloudflared/<UUID>.json
   ingress:
     - hostname: gatekeeper.example.com
       service: http://127.0.0.1:8000
     - service: http_status:404
   ```
6. Avvialo come servizio:
   ```bash
   sudo cloudflared service install
   sudo systemctl enable --now cloudflared
   ```

A questo punto il backend è raggiungibile su
`https://gatekeeper.example.com`.

### Lato app

- Impostazioni → _Accesso remoto_ → incolla l'URL `https://...` e tocca
  **Usa questo URL**: l'app userà subito il tunnel come hub (oppure salva
  l'URL per averlo a portata di mano).
- Quando torni in LAN, basta riaprire la sezione _Connettività_ → _Cambia
  hub_ per tornare alla scansione locale.
- L'URL viene anche memorizzato negli "hub recenti" della schermata di
  discovery: un tap basta per ricollegarsi.

### Sicurezza minima consigliata

- Usa una password forte e MFA sull'account Cloudflare.
- Aggiungi una policy _Cloudflare Access_ sul sottodominio (es. login con
  email magica) per evitare che il backend sia pubblicamente esposto.
- Il backend continua a richiedere il bearer token JWT: il tunnel è solo
  trasporto.

## 13. Notifiche push remote (FCM/APNs)

L'app gestisce già notifiche **locali** (con `flutter_local_notifications`)
e, per la consegna remota anche con app chiusa, ha tutta l'infrastruttura
necessaria lato backend e lato client:

- `users` ha un campo `push_tokens` con le voci `{token, platform,
  registered_at}`,
- gli endpoint `POST /users/me/push-token` e
  `DELETE /users/me/push-token?token=...` registrano/rimuovono i token,
- la sezione _Impostazioni → Notifiche push_ ha un toggle che inizializza
  `PushNotificationsService` e invia il token al backend.

Per **attivare davvero** le push servono pochi passi che devi fornirmi
tu (ti basta passare i file di config):

1. Crea un progetto su Firebase Console.
2. Aggiungi un'app **Android** (package `com.example.gatekeeper_app` o quello
   reale) e/o **iOS**:
   - Android: scarica `google-services.json` e mettilo in
     `app/android/app/`.
   - iOS: scarica `GoogleService-Info.plist` e mettilo in
     `app/ios/Runner/`.
3. Aggiungi alle dipendenze (apri `app/pubspec.yaml`):
   ```yaml
   firebase_core: ^3.6.0
   firebase_messaging: ^15.1.3
   ```
4. Esegui `flutterfire configure` (CLI di FlutterFire) per generare
   `firebase_options.dart`.
5. In `app/lib/data/services/push_notifications_service.dart` sostituisci
   il TODO nel metodo `_tryGetFcmToken()` con:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   final messaging = FirebaseMessaging.instance;
   await messaging.requestPermission();
   return await messaging.getToken();
   ```
6. Lato backend, per inviare effettivamente le notifiche, basta aggiungere
   un worker (in `backend/app/services/`) che usa la _Server Key_ FCM
   (o le credenziali APNs) per fare `POST` a
   `https://fcm.googleapis.com/v1/projects/<project_id>/messages:send`
   verso i `push_tokens` dei membri interessati. Quel worker non è ancora
   incluso perché dipende dai segreti che fornirai.

In sintesi, per attivare le push push:
- mi servono **`google-services.json`** (Android) e/o
  **`GoogleService-Info.plist`** (iOS) e la **Server Key FCM**;
- li metto nei posti giusti e completo il `_tryGetFcmToken` + invio dal
  backend.

## 14. Setup e avvio

Requisiti: Flutter stable >= 3.41.

```powershell
cd app
flutter pub get
flutter run -d windows   # desktop nativo
flutter run -d chrome    # browser
flutter test             # test
```

Il primo avvio web genera anche le risorse in `web/` (già committate).

## 15. Test

`test/widget_test.dart` esegue un piccolo smoke test:

- inizializza `SharedPreferences` in-memory,
- crea il `SettingsController`,
- monta la `GateKeeperApp` e verifica la presenza di "Dashboard" nella UI.

## 16. Note didattiche (per imparare Flutter da questa app)

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

## 17. TODO noti

- Refresh token e revoca server-side dei token (oggi il token è solo verificato
  via HMAC + TTL).
- Worker backend per consegna effettiva delle push (richiede Server Key FCM).
- Endpoint `/events/{id}/resolve` per persistere la risoluzione di un alert
  (oggi è solo locale al client).
- Test widget per il wizard di onboarding e per il flusso di registrazione
  invitato.

## 18. Convenzioni commenti

Tutti i commenti seguono la regola del progetto: iniziano con `//` senza
spazio, terminano con un punto, sono in italiano. Esempi:

```dart
//Commento.
//TODO: collegare il backend.
//FIXME: gestire timeout di rete.
```

