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

## 8. Integrazione backend (TODO prossimo step)

L'app è progettata per essere agganciata al backend FastAPI senza riscritture:

- creare un layer `lib/data/api/` con un client HTTP (es. `dio`/`http`),
- aggiungere `lib/data/repositories/` con `UserRepository`,
  `DeviceRepository`, `EventRepository`,
- sostituire ogni accesso a `MockData` con il repository,
- introdurre (se serve) un piccolo store/cache (es. `riverpod`,
  oppure `ValueNotifier` per restare minimal).

Endpoint noti (dal backend del progetto):

- `/` server status,
- `/users`, `/devices`, `/user-devices`, `/logs`, `/events` con CRUD.

L'onboarding e il pairing con il Raspberry Pi (BLE/Cloudflare Tunnel)
verranno aggiunti in un secondo step (vedi TODO sotto).

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

## 12. TODO noti

- Integrazione reale col backend FastAPI (sostituire `MockData`).
- Onboarding/pairing Raspberry Pi (BLE + Cloudflare Tunnel/Zero Trust).
- Notifiche push (FCM/APNs) con piano e schermata gestione canali.
- Auth con JWT, gestione sessione e refresh token.
- Generare `app_localizations.dart` da `.arb` (quando lo si vuole integrare
  con strumenti di traduzione esterni); ora `AppL10n` runtime è sufficiente.
- Test widget e unitari per ogni feature.

## 13. Convenzioni commenti

Tutti i commenti seguono la regola del progetto: iniziano con `//` senza
spazio, terminano con un punto, sono in italiano. Esempi:

```dart
//Commento.
//TODO: collegare il backend.
//FIXME: gestire timeout di rete.
```

