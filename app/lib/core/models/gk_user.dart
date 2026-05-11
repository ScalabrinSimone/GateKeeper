// ============================================================
// GkUser — modello dati per un utente della casa GateKeeper
// ============================================================
//
// Questo file definisce la struttura dati di un utente.
// In Flutter i "modelli" sono semplici classi Dart (no ORM,
// no annotation magic) che si serializzano da/a JSON.
//
// Pattern usato: factory constructor + toJson()
// - fromJson(Map<String, dynamic> json): costruisce l'oggetto da JSON (API)
// - toJson(): serializza l'oggetto in Map per inviarlo all'API
//
// TODO: quando il backend sarà pronto, verificare che i campi
//       corrispondano esattamente allo schema Pydantic in
//       backend/app/models/schemas.py

/// Ruolo dell'utente all'interno della casa.
/// Determina le autorizzazioni nell'app.
enum UserRole {
  /// Amministratore: accesso completo, gestisce utenti e oggetti.
  admin,

  /// Utente adulto: accesso alla dashboard e notifiche.
  adult,

  /// Utente bambino: visibilità limitata, nessuna modifica.
  child,
}

/// Rappresenta un utente registrato nel sistema GateKeeper.
///
/// Viene usato in tutto l'app per mostrare info utente,
/// gestire i permessi e associare eventi RFID/BLE alle persone.
///
/// Esempio di utilizzo:
/// ```dart
/// final user = GkUser.fromJson(responseBody);
/// print(user.displayName); // "Mario Rossi"
/// ```
class GkUser {
  /// ID univoco assegnato dal backend (UUID o int a seconda del DB).
  final String id;

  /// Nome visualizzato nell'app (es. "Mario").
  final String displayName;

  /// Email usata per il login.
  final String email;

  /// Ruolo che determina i permessi (admin / adult / child).
  final UserRole role;

  /// URL dell'immagine profilo. Può essere null se non impostata.
  final String? avatarUrl;

  /// Indirizzo MAC del dispositivo BLE associato a questo utente.
  /// Usato dal Raspberry per identificare chi è vicino alla porta.
  /// Null se l'utente non ha ancora associato un dispositivo.
  // TODO: aggiungere UI per pairing dispositivo BLE (settings screen)
  final String? bleDeviceMac;

  /// True se l'utente è attualmente dentro casa secondo l'ultimo evento.
  final bool isHome;

  /// Data di creazione dell'account (ricevuta dal backend come ISO 8601).
  final DateTime createdAt;

  const GkUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.bleDeviceMac,
    required this.isHome,
    required this.createdAt,
  });

  // ── Deserializzazione (JSON → GkUser) ──────────────────────────────────
  // factory constructor: come un costruttore normale ma può ritornare
  // un'istanza già esistente o fare logica prima di costruire l'oggetto.

  /// Costruisce un [GkUser] da una [Map] JSON ricevuta dall'API.
  ///
  /// - [json]: la Map ottenuta da `jsonDecode(response.body)['user']`
  factory GkUser.fromJson(Map<String, dynamic> json) {
    return GkUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      // _roleFromString converte la stringa "admin"/"adult"/"child"
      // nell'enum corrispondente.
      role: _roleFromString(json['role'] as String),
      avatarUrl: json['avatar_url'] as String?,
      bleDeviceMac: json['ble_device_mac'] as String?,
      isHome: json['is_home'] as bool? ?? false,
      // DateTime.parse accetta il formato ISO 8601 restituito da FastAPI.
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── Serializzazione (GkUser → JSON) ────────────────────────────────────

  /// Converte il modello in [Map] da inviare all'API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'role': role.name, // enum.name restituisce la stringa es. "admin"
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bleDeviceMac != null) 'ble_device_mac': bleDeviceMac,
      'is_home': isHome,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ── copyWith ─────────────────────────────────────────────────────────
  // Pattern immutabile: invece di modificare l'oggetto, crei una copia
  // con i campi che vuoi cambiare. Utile con Provider/setState.

  /// Crea una copia del modello con alcuni campi modificati.
  GkUser copyWith({
    String? displayName,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? bleDeviceMac,
    bool? isHome,
  }) {
    return GkUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bleDeviceMac: bleDeviceMac ?? this.bleDeviceMac,
      isHome: isHome ?? this.isHome,
      createdAt: createdAt,
    );
  }

  // ── Helper privato ─────────────────────────────────────────────────────

  static UserRole _roleFromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'adult':
        return UserRole.adult;
      case 'child':
        return UserRole.child;
      default:
        // Fallback sicuro: se arriva un ruolo sconosciuto → adult
        return UserRole.adult;
    }
  }

  @override
  String toString() =>
      'GkUser(id: $id, displayName: $displayName, role: ${role.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GkUser && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ── Dati fake per lo sviluppo UI ───────────────────────────────────────
// TODO: rimuovere quando ApiService.getUsers() è connesso al backend reale.
// Questi dati servono per testare l'interfaccia senza il Raspberry attivo.

/// Lista di utenti fake usata nei widget durante lo sviluppo.
const List<Map<String, dynamic>> kFakeUsersJson = [
  {
    'id': 'u-001',
    'display_name': 'Simone',
    'email': 'simone@gatekeeper.local',
    'role': 'admin',
    'avatar_url': null,
    'ble_device_mac': 'AA:BB:CC:DD:EE:FF',
    'is_home': true,
    'created_at': '2025-09-01T10:00:00.000Z',
  },
  {
    'id': 'u-002',
    'display_name': 'Mamma',
    'email': 'mamma@gatekeeper.local',
    'role': 'adult',
    'avatar_url': null,
    'ble_device_mac': null,
    'is_home': false,
    'created_at': '2025-09-02T10:00:00.000Z',
  },
  {
    'id': 'u-003',
    'display_name': 'Fratello',
    'email': 'fratello@gatekeeper.local',
    'role': 'child',
    'avatar_url': null,
    'ble_device_mac': null,
    'is_home': true,
    'created_at': '2025-09-03T10:00:00.000Z',
  },
];
