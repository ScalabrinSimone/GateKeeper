import 'enums.dart';

//Modello utente del sistema casa.
//Campi pensati per essere mappati 1:1 con users del backend (role, is_active, last_seen_at, current_location).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.isInside,
    this.lastSeenAt,
    this.avatarUrl,
    this.isActive = true,
    this.currentLocation,
  });

  final String id;
  final String name;
  final UserRole role;
  final bool isInside;
  final DateTime? lastSeenAt;
  final String? avatarUrl;
  final bool isActive;
  final String? currentLocation;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
