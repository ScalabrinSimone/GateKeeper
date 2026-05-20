import 'dart:convert';

import '../../shared/models/app_user.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/models/smart_object.dart';
import '../api/api_exception.dart';
import '../api/dto.dart';
import '../gatekeeper_api.dart';

//Repository: trasformano DTO -> modelli di dominio dell'app.
//Sono singleton stateless per semplicità.

class UsersRepository {
  static Future<List<AppUser>> list() async {
    final dtos = await GateKeeperApi.instance.users.list();
    return dtos.map(_map).toList();
  }

  static AppUser _map(UserDto u) {
    return AppUser(
      id: u.id.toString(),
      name: u.username,
      role: _roleFrom(u.role),
      isInside: (u.currentLocation ?? 'unknown') == 'inside',
      lastSeenAt: u.lastSeenAt == null ? null : DateTime.tryParse(u.lastSeenAt!),
      isActive: u.isActive,
      currentLocation: u.currentLocation,
      email: u.email,
      permissions: u.permissions,
    );
  }

  //Helper esposto: mappa esplicita per UI che già parte da DTO.
  static AppUser fromDto(UserDto u) => _map(u);

  static UserRole _roleFrom(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'child':
        return UserRole.child;
      default:
        return UserRole.adult;
    }
  }
}

class DevicesRepository {
  static Future<List<SmartObject>> list() async {
    final dtos = await GateKeeperApi.instance.devices.list();
    return dtos.map(_map).toList();
  }

  static SmartObject _map(DeviceDto d) {
    return SmartObject(
      id: d.id.toString(),
      name: d.name,
      rfidTag: d.rfidTag,
      category: _categoryFrom(d.category),
      isInside: d.currentStatus == 'inside',
      isEssential: d.isEssential,
    );
  }

  static ObjectCategory _categoryFrom(String cat) {
    switch (cat.toLowerCase()) {
      case 'keys':
        return ObjectCategory.keys;
      case 'wallet':
        return ObjectCategory.wallet;
      case 'umbrella':
        return ObjectCategory.umbrella;
      case 'bag':
        return ObjectCategory.bag;
      case 'phone':
        return ObjectCategory.phone;
      default:
        return ObjectCategory.other;
    }
  }
}

class EventsRepository {
  //Ritorna gli eventi più recenti, normalizzati a GateEvent.
  static Future<List<GateEvent>> list() async {
    final dtos = await GateKeeperApi.instance.events.list();
    final mapped = dtos.map(_map).toList();
    //Ordina dal più recente al più vecchio.
    mapped.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return mapped;
  }

  static GateEvent _map(EventDto e) {
    final type = _typeFrom(e.eventType);
    final severity = type == EventType.risk ? EventSeverity.critical : EventSeverity.info;
    final ts = DateTime.tryParse(e.createdAt) ?? DateTime.now();
    //I campi detected_* arrivano come JSON-string: li parsiamo soft.
    final users = _safeParseList(e.detectedUsers);
    final objs = _safeParseList(e.detectedObjects);
    final userIds = <String>[
      if (e.userId != null) e.userId!.toString(),
      for (final u in users)
        if (u is Map && u['user_id'] != null) u['user_id'].toString(),
    ].toSet().toList();
    final objectIds = <String>[
      for (final o in objs)
        if (o is Map && o['id'] != null) o['id'].toString()
        else if (o is Map && o['rfid_tag'] != null) o['rfid_tag'].toString(),
    ];

    return GateEvent(
      id: e.id.toString(),
      timestamp: ts,
      type: type,
      severity: severity,
      direction: e.direction == 'in'
          ? GateDirection.entry
          : (e.direction == 'out' ? GateDirection.exit : null),
      userIds: userIds,
      objectIds: objectIds,
      descriptionIt: _describe(type, e, langIt: true),
      descriptionEn: _describe(type, e, langIt: false),
      resolved: type == EventType.risk ? false : null,
    );
  }

  static List<dynamic> _safeParseList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return const [];
  }

  static EventType _typeFrom(String raw) {
    switch (raw) {
      case 'passage_in':
        return EventType.entry;
      case 'passage_out':
        return EventType.exit;
      case 'alert':
        return EventType.risk;
      default:
        return EventType.system;
    }
  }

  //Genera descrizioni dettagliate: estrae nomi oggetti e utenti dai campi JSON.
  static String _describe(EventType type, EventDto e, {required bool langIt}) {
    final objs = _safeParseList(e.detectedObjects);
    final users = _safeParseList(e.detectedUsers);

    //Estrai nomi oggetti.
    final objNames = <String>[];
    for (final o in objs) {
      if (o is Map) {
        final name = o['name']?.toString();
        if (name != null && name.isNotEmpty) objNames.add('"$name"');
      }
    }

    //Estrai nomi utenti.
    final userNames = <String>[];
    for (final u in users) {
      if (u is Map) {
        final name = u['username']?.toString();
        if (name != null && name.isNotEmpty) userNames.add(name);
      }
    }

    final objStr = objNames.isEmpty ? null : objNames.join(', ');
    final userStr = userNames.isEmpty ? null : userNames.join(', ');

    switch (type) {
      case EventType.entry:
        if (userStr != null && objStr != null) {
          return langIt
              ? '$userStr è rientrato con $objStr.'
              : '$userStr came back with $objStr.';
        } else if (userStr != null) {
          return langIt ? '$userStr è rientrato.' : '$userStr came back home.';
        } else if (objStr != null) {
          return langIt ? '$objStr è rientrato.' : '$objStr came back inside.';
        }
        return langIt ? 'Ingresso rilevato alla porta.' : 'Entry detected at the door.';

      case EventType.exit:
        if (userStr != null && objStr != null) {
          return langIt
              ? '$userStr è uscito con $objStr.'
              : '$userStr left with $objStr.';
        } else if (userStr != null) {
          return langIt ? '$userStr è uscito.' : '$userStr left home.';
        } else if (objStr != null) {
          return langIt ? '$objStr è uscito.' : '$objStr went outside.';
        }
        return langIt ? 'Uscita rilevata alla porta.' : 'Exit detected at the door.';

      case EventType.risk:
        if (objStr != null) {
          return langIt
              ? 'Avviso: $objStr in movimento senza utente associato!'
              : 'Alert: $objStr moved without an associated user!';
        }
        return langIt
            ? 'Avviso: oggetto in uscita senza utente rilevato!'
            : 'Alert: object exited without a detected user!';

      case EventType.system:
        final tag = objs.isNotEmpty && objs[0] is Map
            ? objs[0]['rfid_tag']?.toString()
            : null;
        if (tag != null) {
          return langIt ? 'Tag RFID $tag rilevato.' : 'RFID tag $tag detected.';
        }
        return langIt ? 'Evento di sistema.' : 'System event.';
    }
  }
}

//Helper unico che provoca eccezioni tracciabili nelle view.
class RepoError implements Exception {
  RepoError(this.message);
  final String message;

  factory RepoError.fromApi(ApiException e) => RepoError(e.message);

  @override
  String toString() => message;
}
