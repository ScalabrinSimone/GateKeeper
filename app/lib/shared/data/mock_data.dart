import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/gate_event.dart';
import '../models/smart_object.dart';

//Dati di esempio per l'app (separati nettamente dai service futuri).
//TODO: sostituire questo file con repository/service che parlano col backend FastAPI.
class MockData {
  MockData._();

  static final DateTime _now = DateTime.now();

  static final List<AppUser> users = <AppUser>[
    AppUser(
      id: 'u1',
      name: 'Marco Rossi',
      role: UserRole.admin,
      isInside: true,
      lastSeenAt: _now,
      currentLocation: 'inside',
    ),
    AppUser(
      id: 'u2',
      name: 'Elena Rossi',
      role: UserRole.adult,
      isInside: false,
      lastSeenAt: _now.subtract(const Duration(hours: 1)),
      currentLocation: 'outside',
    ),
    AppUser(
      id: 'u3',
      name: 'Luca Rossi',
      role: UserRole.child,
      isInside: true,
      lastSeenAt: _now,
      currentLocation: 'inside',
    ),
    AppUser(
      id: 'u4',
      name: 'Sofia Rossi',
      role: UserRole.child,
      isInside: false,
      lastSeenAt: _now.subtract(const Duration(minutes: 35)),
      currentLocation: 'school',
    ),
  ];

  static final List<SmartObject> objects = <SmartObject>[
    SmartObject(
      id: 'o1',
      name: 'Chiavi Auto',
      rfidTag: 'RFID_001',
      category: ObjectCategory.keys,
      isInside: true,
      isEssential: true,
      lastMovementAt: _now.subtract(const Duration(minutes: 12)),
    ),
    SmartObject(
      id: 'o2',
      name: 'Ombrello Rosso',
      rfidTag: 'RFID_002',
      category: ObjectCategory.umbrella,
      isInside: true,
      lastMovementAt: _now.subtract(const Duration(hours: 6)),
    ),
    SmartObject(
      id: 'o3',
      name: 'Zaino Scuola',
      rfidTag: 'RFID_003',
      category: ObjectCategory.bag,
      ownerId: 'u3',
      isInside: false,
      isEssential: true,
      lastMovementAt: _now.subtract(const Duration(minutes: 35)),
    ),
    SmartObject(
      id: 'o4',
      name: 'Portafoglio Papà',
      rfidTag: 'RFID_004',
      category: ObjectCategory.wallet,
      ownerId: 'u1',
      isInside: true,
      isEssential: true,
      lastMovementAt: _now.subtract(const Duration(hours: 2)),
    ),
    SmartObject(
      id: 'o5',
      name: 'Telefono Luca',
      rfidTag: 'RFID_005',
      category: ObjectCategory.phone,
      ownerId: 'u3',
      isInside: true,
      lastMovementAt: _now.subtract(const Duration(minutes: 5)),
    ),
  ];

  static final List<GateEvent> events = <GateEvent>[
    GateEvent(
      id: 'e1',
      timestamp: _now,
      type: EventType.entry,
      direction: GateDirection.entry,
      severity: EventSeverity.info,
      userIds: const ['u1'],
      descriptionIt: 'Marco è rientrato in casa.',
      descriptionEn: 'Marco entered the house.',
    ),
    GateEvent(
      id: 'e2',
      timestamp: _now.subtract(const Duration(minutes: 25)),
      type: EventType.exit,
      direction: GateDirection.exit,
      severity: EventSeverity.info,
      objectIds: const ['o3'],
      userIds: const ['u3'],
      descriptionIt: 'Zaino Scuola portato fuori da Luca.',
      descriptionEn: 'School backpack taken out by Luca.',
    ),
    GateEvent(
      id: 'e3',
      timestamp: _now.subtract(const Duration(hours: 1, minutes: 23)),
      type: EventType.risk,
      severity: EventSeverity.critical,
      userIds: const ['u4'],
      descriptionIt: 'Sofia è uscita senza il suo telefono!',
      descriptionEn: 'Sofia left without her phone!',
      resolved: false,
    ),
    GateEvent(
      id: 'e4',
      timestamp: _now.subtract(const Duration(hours: 2)),
      type: EventType.risk,
      severity: EventSeverity.critical,
      objectIds: const ['o1'],
      descriptionIt: 'Chiavi dimenticate nella serratura esterna.',
      descriptionEn: 'Keys forgotten in the external lock.',
      resolved: false,
    ),
    GateEvent(
      id: 'e5',
      timestamp: _now.subtract(const Duration(hours: 4)),
      type: EventType.exit,
      direction: GateDirection.exit,
      severity: EventSeverity.info,
      objectIds: const ['o2'],
      descriptionIt: 'Ombrello Rosso portato fuori (previsto sole).',
      descriptionEn: 'Red umbrella taken out (sun predicted).',
    ),
    GateEvent(
      id: 'e6',
      timestamp: _now.subtract(const Duration(days: 1, hours: 2)),
      type: EventType.entry,
      direction: GateDirection.entry,
      severity: EventSeverity.info,
      userIds: const ['u2'],
      descriptionIt: 'Elena è rientrata in casa.',
      descriptionEn: 'Elena entered the house.',
    ),
  ];
}
