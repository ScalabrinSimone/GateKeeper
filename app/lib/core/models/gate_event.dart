// ============================================================
// GateEvent — modello dati per un evento porta rilevato dal sistema
// ============================================================
//
// Ogni volta che il reader RFID + BLE rilevano un movimento
// (entrata o uscita) il Raspberry genera un GateEvent.
// Questo modello rappresenta quell'evento nell'app Flutter.
//
// TODO: allineare i campi con backend/app/models/schemas.py → EventSchema

/// Direzione del passaggio rilevato dalla porta.
enum EventDirection {
  /// Oggetto/utente è uscito di casa.
  exit,

  /// Oggetto/utente è rientrato in casa.
  entry,
}

/// Livello di priorità/importanza dell'evento per le notifiche.
enum EventSeverity {
  /// Evento normale, solo informativo.
  info,

  /// Qualcosa da tenere d'occhio (es. bambino uscito senza adulto).
  warning,

  /// Evento critico (es. oggetto sensibile portato fuori senza utente noto).
  critical,
}

/// Rappresenta un singolo evento rilevato dalla porta GateKeeper.
///
/// Contiene informazioni su chi è passato (utente identificato via BLE),
/// cosa è passato (oggetti rilevati via RFID) e quando.
///
/// Gli eventi sono la "memoria" del sistema: vengono mostrati
/// nella schermata Events in ordine cronologico.
///
/// Esempio:
/// ```dart
/// final event = GateEvent.fromJson(json);
/// final dir = event.direction == EventDirection.exit ? 'uscito' : 'rientrato';
/// print('${event.userDisplayName} è $dir');
/// ```
class GateEvent {
  /// ID univoco dell'evento (UUID generato dal backend).
  final String id;

  /// Momento in cui è stato rilevato l'evento (ora del Raspberry).
  final DateTime timestamp;

  /// Direzione del passaggio: uscita o entrata.
  final EventDirection direction;

  /// ID dell'utente associato all'evento tramite BLE.
  /// Null se nessun telefono BLE è stato rilevato vicino alla porta
  /// (potrebbe essere un estraneo o l'utente senza telefono).
  final String? userId;

  /// Nome visualizzato dell'utente (denormalizzato dal backend per comodità).
  /// Null se userId è null.
  final String? userDisplayName;

  /// Lista dei tag RFID degli oggetti passati con questo evento.
  /// Può essere vuota se solo l'utente è passato senza oggetti rilevati.
  final List<String> rfidTags;

  /// Lista dei nomi degli oggetti (denormalizzati dal backend).
  final List<String> objectNames;

  /// Livello di severità: info, warning, critical.
  final EventSeverity severity;

  /// Messaggio di notifica generato dal backend
  /// (es. "Simone è uscito senza ombrello ☔").
  final String? notificationMessage;

  const GateEvent({
    required this.id,
    required this.timestamp,
    required this.direction,
    this.userId,
    this.userDisplayName,
    required this.rfidTags,
    required this.objectNames,
    required this.severity,
    this.notificationMessage,
  });

  /// Costruisce un [GateEvent] da JSON ricevuto dall'API.
  factory GateEvent.fromJson(Map<String, dynamic> json) {
    return GateEvent(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      direction: json['direction'] == 'exit'
          ? EventDirection.exit
          : EventDirection.entry,
      userId: json['user_id'] as String?,
      userDisplayName: json['user_display_name'] as String?,
      rfidTags: List<String>.from(json['rfid_tags'] as List? ?? []),
      objectNames: List<String>.from(json['object_names'] as List? ?? []),
      severity: _severityFromString(json['severity'] as String? ?? 'info'),
      notificationMessage: json['notification_message'] as String?,
    );
  }

  /// Serializza l'evento in Map.
  /// Nota: di solito gli eventi li crea il backend, non il client.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'direction': direction.name,
      if (userId != null) 'user_id': userId,
      if (userDisplayName != null) 'user_display_name': userDisplayName,
      'rfid_tags': rfidTags,
      'object_names': objectNames,
      'severity': severity.name,
      if (notificationMessage != null)
        'notification_message': notificationMessage,
    };
  }

  /// True se l'evento ha generato una notifica di warning o critica.
  bool get hasAlert => severity != EventSeverity.info;

  static EventSeverity _severityFromString(String value) {
    switch (value) {
      case 'warning':
        return EventSeverity.warning;
      case 'critical':
        return EventSeverity.critical;
      default:
        return EventSeverity.info;
    }
  }

  @override
  String toString() =>
      'GateEvent(id: $id, dir: ${direction.name}, user: $userDisplayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GateEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ── Dati fake per lo sviluppo UI ──────────────────────────────────────
// TODO: rimuovere quando ApiService.getEvents() è connesso al backend.
final List<Map<String, dynamic>> kFakeEventsJson = [
  {
    'id': 'ev-001',
    'timestamp': DateTime.now()
        .subtract(const Duration(minutes: 15))
        .toIso8601String(),
    'direction': 'exit',
    'user_id': 'u-001',
    'user_display_name': 'Simone',
    'rfid_tags': ['E200100860B20004'],
    'object_names': ['MacBook'],
    'severity': 'info',
    'notification_message': null,
  },
  {
    'id': 'ev-002',
    'timestamp': DateTime.now()
        .subtract(const Duration(hours: 2))
        .toIso8601String(),
    'direction': 'exit',
    'user_id': 'u-003',
    'user_display_name': 'Fratello',
    'rfid_tags': [],
    'object_names': [],
    'severity': 'warning',
    'notification_message': 'Fratello è uscito senza telefono',
  },
  {
    'id': 'ev-003',
    'timestamp': DateTime.now()
        .subtract(const Duration(hours: 5))
        .toIso8601String(),
    'direction': 'entry',
    'user_id': 'u-002',
    'user_display_name': 'Mamma',
    'rfid_tags': ['E200100860B20003'],
    'object_names': ['Zaino scuola'],
    'severity': 'info',
    'notification_message': null,
  },
  {
    'id': 'ev-004',
    'timestamp': DateTime.now()
        .subtract(const Duration(hours: 8))
        .toIso8601String(),
    'direction': 'exit',
    'user_id': null,
    'user_display_name': null,
    'rfid_tags': ['E200100860B20001'],
    'object_names': ['Chiavi di casa'],
    'severity': 'critical',
    'notification_message': 'Chiavi uscite senza utente identificato ⚠️',
  },
];
