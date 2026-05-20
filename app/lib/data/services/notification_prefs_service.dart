import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

//Preferenze di notifica per singola entità (membro o oggetto).
class EntityNotifPrefs {
  const EntityNotifPrefs({
    this.onEntry = true,
    this.onExit = true,
    this.timeFrom,
    this.timeTo,
  });

  //Notifica quando questa entità entra.
  final bool onEntry;
  //Notifica quando questa entità esce.
  final bool onExit;
  //Finestra oraria opzionale: notifica solo tra questi orari.
  //Formato "HH:mm". Null = sempre.
  final String? timeFrom;
  final String? timeTo;

  bool get hasTimeWindow => timeFrom != null && timeTo != null;

  Map<String, dynamic> toJson() => {
        'onEntry': onEntry,
        'onExit': onExit,
        if (timeFrom != null) 'timeFrom': timeFrom,
        if (timeTo != null) 'timeTo': timeTo,
      };

  factory EntityNotifPrefs.fromJson(Map<String, dynamic> j) =>
      EntityNotifPrefs(
        onEntry: j['onEntry'] as bool? ?? true,
        onExit: j['onExit'] as bool? ?? true,
        timeFrom: j['timeFrom'] as String?,
        timeTo: j['timeTo'] as String?,
      );

  EntityNotifPrefs copyWith({
    bool? onEntry,
    bool? onExit,
    String? timeFrom,
    String? timeTo,
    bool clearTime = false,
  }) =>
      EntityNotifPrefs(
        onEntry: onEntry ?? this.onEntry,
        onExit: onExit ?? this.onExit,
        timeFrom: clearTime ? null : (timeFrom ?? this.timeFrom),
        timeTo: clearTime ? null : (timeTo ?? this.timeTo),
      );
}

//Servizio di persistenza delle preferenze notifica, per utente dell'app.
//La chiave è: gk.notif_pref.<viewerUserId>.<entityId>
//Ogni viewer (utente loggato) ha preferenze indipendenti per ogni entità.
class NotificationPrefsService {
  NotificationPrefsService._();
  static final NotificationPrefsService instance = NotificationPrefsService._();

  static const _prefix = 'gk.notif_pref.';

  String _key(String viewerUserId, String entityId) =>
      '$_prefix${viewerUserId}_$entityId';

  Future<EntityNotifPrefs> load(String viewerUserId, String entityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(viewerUserId, entityId));
      if (raw == null) return const EntityNotifPrefs();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return EntityNotifPrefs.fromJson(json);
    } catch (_) {
      return const EntityNotifPrefs();
    }
  }

  Future<void> save(
      String viewerUserId, String entityId, EntityNotifPrefs prefs) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key(viewerUserId, entityId), jsonEncode(prefs.toJson()));
    } catch (_) {}
  }
}
