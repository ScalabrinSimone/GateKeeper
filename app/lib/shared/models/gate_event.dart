import 'enums.dart';

//Evento rilevato dal sistema (passaggio, alert, risk).
//Pensato per riflettere events del backend: event_type, direction, detected_objects, detected_users.
class GateEvent {
  GateEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.descriptionIt,
    required this.descriptionEn,
    this.direction,
    this.userIds = const [],
    this.objectIds = const [],
    this.resolved,
  });

  final String id;
  final DateTime timestamp;
  final EventType type;
  final EventSeverity severity;
  final String descriptionIt;
  final String descriptionEn;
  final GateDirection? direction;
  final List<String> userIds;
  final List<String> objectIds;
  bool? resolved;

  String descriptionFor(String languageCode) =>
      languageCode == 'en' ? descriptionEn : descriptionIt;

  bool get isCritical => severity == EventSeverity.critical;
  bool get isUnresolved => isCritical && (resolved == false);
}
