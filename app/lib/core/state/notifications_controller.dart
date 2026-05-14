import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform/platform_info.dart';

//Controller di notifiche locali multipiattaforma.
//Usa flutter_local_notifications per Android/iOS/macOS/Linux/Windows.
//Sul web le notifiche di sistema non sono supportate uniformemente: il controller
//resta inerte (no-op) per evitare crash.
//
//Nota: questa è la base per ricevere notifiche anche quando l'app è chiusa
//su mobile. Per il push remoto vero e proprio (server -> dispositivo) servirà
//FCM/APNs in un secondo momento; intanto l'hub può inviarle quando l'app è
//connessa (poll/long-poll del feed eventi).
class NotificationsController {
  NotificationsController._();

  static final NotificationsController instance = NotificationsController._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _supported = false;

  bool get supported => _supported;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    //Sul web non c'è un'implementazione cross-browser stabile.
    if (PlatformInfo.isWeb) {
      _supported = false;
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxInit = LinuxInitializationSettings(defaultActionName: 'Apri');

      const settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
        linux: linuxInit,
      );

      await _plugin.initialize(settings);
      _supported = true;

      //Richiesta permessi su Android 13+ e iOS.
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {}
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Notifications] init error: $e');
      }
      _supported = false;
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    bool important = false,
  }) async {
    if (!_supported) return;
    final android = AndroidNotificationDetails(
      important ? 'gatekeeper_critical' : 'gatekeeper_default',
      important ? 'Avvisi importanti' : 'Notifiche GateKeeper',
      channelDescription: 'Notifiche del sistema GateKeeper',
      importance: important ? Importance.max : Importance.defaultImportance,
      priority: important ? Priority.high : Priority.defaultPriority,
      playSound: true,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: const LinuxNotificationDetails(),
    );
    try {
      await _plugin.show(id, title, body, details);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Notifications] show error: $e');
      }
    }
  }
}
