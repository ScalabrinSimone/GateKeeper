// ============================================================
// RfidObject — modello dati per un oggetto taggato con RFID
// ============================================================
//
// Ogni oggetto fisico (chiavi, ombrello, zaino…) registrato
// nel sistema è rappresentato da questo modello.
// Il tag RFID (campo rfidTag) è l'ID univoco fisico dell'oggetto,
// ovvero l'EPC (Electronic Product Code) letto dal reader UHF.
//
// TODO: quando il backend è pronto, allineare i campi con
//       backend/app/models/schemas.py → RfidObjectSchema

/// Categoria dell'oggetto, usata per icone e filtri nell'UI.
enum ObjectCategory {
  keys,
  umbrella,
  bag,
  electronics,
  documents,
  clothing,
  other,
}

/// Stato corrente dell'oggetto rispetto alla porta di casa.
enum ObjectStatus {
  /// L'oggetto è dentro casa.
  inside,

  /// L'oggetto è uscito di casa.
  outside,

  /// Lo stato non è ancora noto (mai rilevato dal reader RFID).
  unknown,
}

/// Rappresenta un oggetto fisico tracciato via RFID nel sistema GateKeeper.
///
/// Ogni [RfidObject] è associato a un tag RFID UHF fisico.
/// Il Raspberry legge il tag quando l'oggetto passa vicino alla porta
/// e invia un evento al backend.
///
/// Esempio:
/// ```dart
/// final obj = RfidObject.fromJson(json);
/// if (obj.status == ObjectStatus.outside) {
///   // mostra notifica "hai dimenticato X"
/// }
/// ```
class RfidObject {
  /// ID univoco del tag RFID (EPC, formato es. "E200100860B20674").
  final String rfidTag;

  /// Nome leggibile assegnato dall'utente (es. "Chiavi di casa").
  final String name;

  /// Categoria per icona e filtraggio nell'UI.
  final ObjectCategory category;

  /// Stato attuale dell'oggetto (dentro/fuori/sconosciuto).
  final ObjectStatus status;

  /// ID dell'utente proprietario di questo oggetto.
  /// Null se l'oggetto non è assegnato a nessun utente specifico.
  // TODO: aggiungere UI per assegnare/riassegnare il proprietario
  final String? ownerId;

  /// True se l'app deve notificare quando questo oggetto esce senza
  /// che un utente adulto sia presente.
  final bool alertOnUnattendedExit;

  /// Timestamp dell'ultimo evento RFID rilevato per questo oggetto.
  final DateTime? lastSeenAt;

  const RfidObject({
    required this.rfidTag,
    required this.name,
    required this.category,
    required this.status,
    this.ownerId,
    required this.alertOnUnattendedExit,
    this.lastSeenAt,
  });

  /// Costruisce un [RfidObject] da JSON ricevuto dall'API.
  factory RfidObject.fromJson(Map<String, dynamic> json) {
    return RfidObject(
      rfidTag: json['rfid_tag'] as String,
      name: json['name'] as String,
      category: _categoryFromString(json['category'] as String),
      status: _statusFromString(json['status'] as String),
      ownerId: json['owner_id'] as String?,
      alertOnUnattendedExit:
          json['alert_on_unattended_exit'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
    );
  }

  /// Serializza l'oggetto in Map da inviare all'API.
  Map<String, dynamic> toJson() {
    return {
      'rfid_tag': rfidTag,
      'name': name,
      'category': category.name,
      'status': status.name,
      if (ownerId != null) 'owner_id': ownerId,
      'alert_on_unattended_exit': alertOnUnattendedExit,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt!.toIso8601String(),
    };
  }

  /// Crea una copia con alcuni campi modificati.
  RfidObject copyWith({
    String? name,
    ObjectCategory? category,
    ObjectStatus? status,
    String? ownerId,
    bool? alertOnUnattendedExit,
    DateTime? lastSeenAt,
  }) {
    return RfidObject(
      rfidTag: rfidTag,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      alertOnUnattendedExit:
          alertOnUnattendedExit ?? this.alertOnUnattendedExit,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  /// Restituisce l'emoji corrispondente alla categoria (usata nelle card UI).
  String get categoryEmoji {
    switch (category) {
      case ObjectCategory.keys:
        return '🔑';
      case ObjectCategory.umbrella:
        return '☂️';
      case ObjectCategory.bag:
        return '🎒';
      case ObjectCategory.electronics:
        return '💻';
      case ObjectCategory.documents:
        return '📄';
      case ObjectCategory.clothing:
        return '👕';
      case ObjectCategory.other:
        return '📦';
    }
  }

  static ObjectCategory _categoryFromString(String value) {
    return ObjectCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ObjectCategory.other,
    );
  }

  static ObjectStatus _statusFromString(String value) {
    return ObjectStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ObjectStatus.unknown,
    );
  }

  @override
  String toString() =>
      'RfidObject(tag: $rfidTag, name: $name, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RfidObject && other.rfidTag == rfidTag);

  @override
  int get hashCode => rfidTag.hashCode;
}

// ── Dati fake per lo sviluppo UI ──────────────────────────────────────
// TODO: rimuovere quando ApiService.getObjects() è connesso al backend.
const List<Map<String, dynamic>> kFakeObjectsJson = [
  {
    'rfid_tag': 'E200100860B20001',
    'name': 'Chiavi di casa',
    'category': 'keys',
    'status': 'inside',
    'owner_id': 'u-001',
    'alert_on_unattended_exit': true,
    'last_seen_at': '2026-04-29T18:30:00.000Z',
  },
  {
    'rfid_tag': 'E200100860B20002',
    'name': 'Ombrello nero',
    'category': 'umbrella',
    'status': 'outside',
    'owner_id': 'u-001',
    'alert_on_unattended_exit': false,
    'last_seen_at': '2026-04-29T08:15:00.000Z',
  },
  {
    'rfid_tag': 'E200100860B20003',
    'name': 'Zaino scuola',
    'category': 'bag',
    'status': 'inside',
    'owner_id': 'u-003',
    'alert_on_unattended_exit': true,
    'last_seen_at': '2026-04-28T17:00:00.000Z',
  },
  {
    'rfid_tag': 'E200100860B20004',
    'name': 'MacBook',
    'category': 'electronics',
    'status': 'outside',
    'owner_id': 'u-001',
    'alert_on_unattended_exit': false,
    'last_seen_at': '2026-04-29T09:00:00.000Z',
  },
];
