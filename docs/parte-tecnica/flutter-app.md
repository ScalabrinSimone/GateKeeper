# ⚡ App Flutter

## Panoramica

L'app GateKeeper è un'applicazione **Flutter cross-platform** che funge da interfaccia
utente per l'intero sistema IoT. Gira su Android, iOS, macOS, Windows e Web dallo stesso
codebase — senza modifiche.

---

## Architettura dell'app

L'app segue un'architettura a layer semplice e leggibile:

```
app/lib/
├── core/                    # Infrastruttura trasversale
│   ├── config/              # ApiConfig — URL hub persistito
│   ├── i18n/                # Localizzazioni IT/EN (app_l10n.dart)
│   ├── platform/            # PlatformInfo — rilevamento piattaforma
│   ├── state/               # ChangeNotifier: Auth, Settings, Notifications
│   ├── storage/             # SecureStorage (flutter_secure_storage)
│   └── theme/               # AppColors + AppTheme (dark/light)
│
├── data/                    # Layer dati
│   ├── api/                 # Client HTTP + DTOs + endpoint specifici
│   ├── repositories/        # Trasformazione DTO → modelli di dominio
│   └── services/            # RealtimeService, PushNotifications, Discovery
│
├── features/                # Una cartella per ogni schermata
│   ├── account/             # Profilo utente + foto avatar
│   ├── auth/                # Login, recupero password, verifica email
│   ├── dashboard/           # Vista bento real-time
│   ├── events/              # Cronologia eventi con filtri
│   ├── invite/              # Accettazione inviti con email verificata
│   ├── members/             # Lista membri + gestione permessi
│   ├── objects/             # Oggetti RFID + form creazione/modifica
│   ├── onboarding/          # Discovery hub + setup wizard admin
│   └── settings/            # Impostazioni, BLE, tunnel remoto
│
└── shared/                  # Widget e modelli riutilizzabili
    ├── models/              # AppUser, SmartObject, GateEvent, enums
    └── widgets/             # GKButton, GKCard, AppShell, StatusPill…
```

---

## Routing — go_router

La navigazione usa [`go_router`](https://pub.dev/packages/go_router) con redirect
automatici basati sullo stato di autenticazione (`AuthStage`):

```dart
enum AuthStage {
  loading,               // Splash screen
  needsPairing,          // Hub non ancora configurato
  needsLogin,            // Hub paired, utente non loggato
  needsEmailVerification,// Email non verificata
  authenticated,         // App pronta
  offline,               // Hub non raggiungibile
}
```

| Route | Quando | Descrizione |
|-------|--------|-------------|
| `/splash` | loading | Schermata di caricamento |
| `/welcome` | needsPairing | Scelta modalità pairing |
| `/onboarding/discover` | needsPairing | Discovery hub LAN |
| `/onboarding/setup` | needsPairing | Wizard creazione admin |
| `/login` | needsLogin | Schermata login |
| `/verify-email` | needsEmailVerification | Inserimento codice email |
| `/invite/:token` | — | Accettazione invito |
| `/dashboard` | authenticated | Dashboard principale |
| `/events`, `/objects`, `/members`, `/settings`, `/account` | authenticated | Sezioni app |

---

## State management

L'app usa **ChangeNotifier** puro — senza pacchetti di state management esterni.
Questa scelta è intenzionale: è semplice da capire, facile da testare e sufficiente
per le esigenze del progetto.

```
AuthController (ChangeNotifier)
  └── Ascoltato da: go_router (refreshListenable)
  └── Gestisce: login, logout, pairing, verifica email

RealtimeService (ChangeNotifier)
  └── Ascoltato da: DashboardPage (ListenableBuilder)
  └── Gestisce: poll eventi/utenti/oggetti ogni 4-8s
  └── Notifica: NotificationsController per alert locali

SettingsController (ChangeNotifier)
  └── Ascoltato da: AppShell (tema dark/light)
  └── Gestisce: lingua, tema, URL tunnel remoto
```

---

## Real-time updates — RealtimeService

Il `RealtimeService` è il motore del polling automatico:

```dart
// Intervalli configurabili
static const _eventInterval = Duration(seconds: 4);  // eventi
static const _dataInterval  = Duration(seconds: 8);  // utenti + oggetti
```

**Come funziona:**

1. Al login, `start()` viene chiamato dall'`AuthController`
2. Ogni 4s: GET `/events` — se arrivano nuovi eventi, mostra notifica locale
3. Ogni 8s: GET `/devices` + GET `/users` — aggiorna stati IN/OUT
4. `notifyListeners()` viene chiamato solo se i dati sono cambiati
5. `DashboardPage` usa `ListenableBuilder` e si aggiorna automaticamente

Questo approccio funziona su **tutte le piattaforme** (incluso web e desktop)
senza bisogno di WebSocket o Firebase.

---

## Localizzazione IT/EN

L'app supporta italiano e inglese tramite il sistema di localizzazione Flutter.
Le traduzioni sono centralmente gestite in `app/lib/core/i18n/app_l10n.dart`
come mappe di stringhe — senza file `.arb` separati per semplicità.

```dart
// Utilizzo in qualsiasi widget
final l10n = AppL10n.of(context);
Text(l10n.t('dashboard'))   // "Dashboard" o "Dashboard" (uguale in IT/EN)
Text(l10n.t('addObject'))   // "Aggiungi oggetto" o "Add object"
```

---

## Tema — Dark/Light

Il tema usa la palette GateKeeper definita in `AppColors`:

| Nome | Colore | Uso principale |
|------|--------|----------------|
| Ink Black | `#0D1117` | Sfondo dark |
| Charcoal Blue | `#41474E` | Elementi secondari |
| Stormy Teal | `#00767A` | Accento primario, bottoni |
| Orange | `#FFA400` | Alert, accenti caldi |
| Lavender Blush | `#F0E2E7` | Testo su sfondo dark |

---

## Dipendenze Flutter principali

| Pacchetto | Versione | Uso |
|-----------|----------|-----|
| `go_router` | ^14.x | Navigazione con redirect |
| `flutter_svg` | ^2.x | Icone SVG |
| `flutter_localizations` | SDK | Localizzazione sistema |
| `flutter_secure_storage` | ^9.x | Token JWT sicuro |
| `http` | ^1.x | Client HTTP REST |
| `shared_preferences` | ^2.x | Preferenze persistenti |
| `flutter_local_notifications` | ^17.x | Notifiche locali |
| `google_fonts` | ^8.x | Font Inter |
| `mobile_scanner` | ^5.x | Scanner QR |
| `qr_flutter` | ^4.x | Generazione QR |
| `image_picker` | ^1.x | Foto profilo |
| `uuid` | ^4.x | ID locali |

---

## Permessi richiesti

=== "Android"
    ```xml
    <!-- AndroidManifest.xml -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    ```

=== "iOS"
    ```xml
    <!-- Info.plist -->
    <key>NSCameraUsageDescription</key>
    <string>Per scansionare il QR di pairing</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Per caricare la foto profilo</string>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Per il rilevamento presenza alla porta</string>
    ```

---

## Struttura feature — esempio: Objects

Ogni feature segue questa struttura consistente:

```
features/objects/
├── objects_page.dart          # Pagina principale (lista oggetti)
└── widgets/
    └── object_form_sheet.dart # Modal bottom sheet creazione/modifica
```

La pagina legge i dati da `RealtimeService` e ascolta i cambiamenti.
Il form sheet gestisce internamente lo stato locale (scan RFID, icon picker).

---

!!! tip "Nota per chi impara Flutter"
    L'app è volutamente semplice nell'architettura.
    Non usa Bloc, Riverpod o Provider — solo `ChangeNotifier` + `ListenableBuilder`.
    È il modo più diretto per capire come funziona lo state management in Flutter
    prima di introdurre complessità aggiuntiva.
