//Data Transfer Object: rappresentazioni di payload backend.
//Sono pensati per essere semplici da mappare ai modelli UI esistenti.

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.uuid,
    this.isActive = true,
    this.lastSeenAt,
    this.currentLocation,
    this.createdAt,
    this.permissions = const <String, bool>{},
    this.pushTokens = const <Map<String, dynamic>>[],
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final perms = <String, bool>{};
    if (rawPerms is Map) {
      rawPerms.forEach((k, v) => perms[k.toString()] = v == true);
    }
    final rawTokens = json['push_tokens'];
    final tokens = <Map<String, dynamic>>[];
    if (rawTokens is List) {
      for (final t in rawTokens) {
        if (t is Map) tokens.add(Map<String, dynamic>.from(t));
      }
    }
    return UserDto(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? 'adult').toString(),
      uuid: json['uuid']?.toString(),
      isActive: json['is_active'] != false,
      lastSeenAt: json['last_seen_at']?.toString(),
      currentLocation: json['current_location']?.toString(),
      createdAt: json['created_at']?.toString(),
      permissions: perms,
      pushTokens: tokens,
    );
  }

  final int id;
  final String email;
  final String username;
  final String role;
  final String? uuid;
  final bool isActive;
  final String? lastSeenAt;
  final String? currentLocation;
  final String? createdAt;
  //Permessi granulari. Per gli admin sono tutti True (forzati dal backend).
  final Map<String, bool> permissions;
  //Token push registrati (FCM/APNs). Solo lettura.
  final List<Map<String, dynamic>> pushTokens;

  bool get isAdmin => role == 'admin';

  bool can(String key) {
    if (isAdmin) return true;
    return permissions[key] == true;
  }

  UserDto copyWith({
    Map<String, bool>? permissions,
  }) {
    return UserDto(
      id: id,
      email: email,
      username: username,
      role: role,
      uuid: uuid,
      isActive: isActive,
      lastSeenAt: lastSeenAt,
      currentLocation: currentLocation,
      createdAt: createdAt,
      permissions: permissions ?? this.permissions,
      pushTokens: pushTokens,
    );
  }
}

//Permessi granulari noti all'app.
//Tenuti come costanti centralizzate per evitare stringhe sparse nel codice.
class GKPermissions {
  GKPermissions._();
  static const canManageDevices = 'can_manage_devices';
  static const canManageUsers = 'can_manage_users';
  static const canViewEvents = 'can_view_events';
  static const canManageInvites = 'can_manage_invites';
  static const canAcknowledgeAlerts = 'can_acknowledge_alerts';
  static const canConfigureHub = 'can_configure_hub';

  static const all = <String>[
    canManageDevices,
    canManageUsers,
    canViewEvents,
    canManageInvites,
    canAcknowledgeAlerts,
    canConfigureHub,
  ];
}

//Tag RFID rilevato dall'hub ma non ancora associato a un device.
class ScannedTagDto {
  const ScannedTagDto({required this.tag, required this.seenAt});
  factory ScannedTagDto.fromJson(Map<String, dynamic> json) => ScannedTagDto(
        tag: (json['tag'] ?? '').toString(),
        seenAt: (json['seen_at'] ?? '').toString(),
      );
  final String tag;
  final String seenAt;
}

class DeviceDto {
  const DeviceDto({
    required this.id,
    required this.name,
    required this.rfidTag,
    required this.category,
    required this.isEssential,
    required this.currentStatus,
    this.alertRules,
    this.createdAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        rfidTag: (json['rfid_tag'] ?? '').toString(),
        category: (json['category'] ?? 'other').toString(),
        isEssential: json['is_essential'] == true,
        currentStatus: (json['current_status'] ?? 'inside').toString(),
        alertRules: json['alert_rules']?.toString(),
        createdAt: json['created_at']?.toString(),
      );

  final int id;
  final String name;
  final String rfidTag;
  final String category;
  final bool isEssential;
  final String currentStatus;
  final String? alertRules;
  final String? createdAt;
}

class EventDto {
  const EventDto({
    required this.id,
    required this.eventType,
    required this.createdAt,
    this.userId,
    this.direction,
    this.detectedObjects,
    this.detectedUsers,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) => EventDto(
        id: (json['id'] as num).toInt(),
        eventType: (json['event_type'] ?? 'system').toString(),
        createdAt: (json['created_at'] ?? '').toString(),
        userId: (json['user_id'] as num?)?.toInt(),
        direction: json['direction']?.toString(),
        detectedObjects: json['detected_objects']?.toString(),
        detectedUsers: json['detected_users']?.toString(),
      );

  final int id;
  final String eventType;
  final String createdAt;
  final int? userId;
  final String? direction;
  final String? detectedObjects;
  final String? detectedUsers;
}

class LogDto {
  const LogDto({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.action,
    required this.createdAt,
  });

  factory LogDto.fromJson(Map<String, dynamic> json) => LogDto(
        id: (json['id'] as num).toInt(),
        userId: (json['user_id'] as num).toInt(),
        deviceId: (json['device_id'] as num).toInt(),
        action: (json['action'] ?? '').toString(),
        createdAt: (json['created_at'] ?? '').toString(),
      );

  final int id;
  final int userId;
  final int deviceId;
  final String action;
  final String createdAt;
}

class HubInfoDto {
  const HubInfoDto({
    required this.paired,
    required this.requiresFactoryCode,
    this.houseName,
    this.apiVersion,
  });

  factory HubInfoDto.fromJson(Map<String, dynamic> json) => HubInfoDto(
        paired: json['paired'] == true,
        requiresFactoryCode: json['requires_factory_code'] == true,
        houseName: json['house_name']?.toString(),
        apiVersion: json['api_version']?.toString(),
      );

  final bool paired;
  final bool requiresFactoryCode;
  final String? houseName;
  final String? apiVersion;
}

//Payload del QR di pairing pubblicato da GET /hub/qr.
//Lo stesso schema viene stampato nel terminale del Raspberry all'avvio.
class HubQrDto {
  const HubQrDto({
    required this.v,
    required this.kind,
    required this.paired,
    this.baseUrl,
    this.factoryCode,
    this.houseName,
  });

  factory HubQrDto.fromJson(Map<String, dynamic> json) => HubQrDto(
        v: (json['v'] as num?)?.toInt() ?? 1,
        kind: (json['kind'] ?? 'gatekeeper_pair').toString(),
        paired: json['paired'] == true,
        baseUrl: json['base_url']?.toString() ?? json['baseUrl']?.toString(),
        factoryCode:
            json['factory_code']?.toString() ?? json['factoryCode']?.toString(),
        houseName:
            json['house_name']?.toString() ?? json['houseName']?.toString(),
      );

  final int v;
  final String kind;
  final bool paired;
  final String? baseUrl;
  final String? factoryCode;
  final String? houseName;

  bool get looksValid => kind == 'gatekeeper_pair' && (baseUrl?.isNotEmpty ?? false);
}

class AuthResultDto {
  const AuthResultDto({required this.token, required this.user});

  factory AuthResultDto.fromJson(Map<String, dynamic> json) => AuthResultDto(
        token: (json['token'] ?? '').toString(),
        user: UserDto.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      );

  final String token;
  final UserDto user;
}

class InviteDto {
  const InviteDto({
    required this.id,
    required this.token,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    required this.consumed,
    this.suggestedName,
  });

  factory InviteDto.fromJson(Map<String, dynamic> json) => InviteDto(
        id: (json['id'] as num).toInt(),
        token: (json['token'] ?? '').toString(),
        role: (json['role'] ?? 'adult').toString(),
        createdAt: (json['created_at'] ?? '').toString(),
        expiresAt: (json['expires_at'] ?? '').toString(),
        consumed: json['consumed'] == true,
        suggestedName: json['suggested_name']?.toString(),
      );

  final int id;
  final String token;
  final String role;
  final String createdAt;
  final String expiresAt;
  final bool consumed;
  final String? suggestedName;
}
