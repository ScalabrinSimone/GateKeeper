import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform/platform_info.dart';

//Controller di notifiche locali multipiattaforma.
//Usa flutter_local_notifications per Android/iOS/macOS/Linux.
//Sul web e su Windows le notifiche di sistema non sono supportate
//uniformemente: il controller resta inerte (no-op) per evitare crash.
//
//Nota: questa è la base per ricevere notifiche anche quando l'app è chiusa
//su mobile. Per il push remoto vero e proprio (server -> dispositivo) servirà
//FCM/APNs in un secondo momento.
class NotificationsController {
  NotificationsController._();

  static final NotificationsController instance = NotificationsController._();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;
  bool _supported = false;

  bool get supported => _supported;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    //Sul web e su Windows non c'è un'implementazione cross-browser/desktop stabile.
    if (PlatformInfo.isWeb) {
      _supported = false;
      return;
    }

    //Windows non è ufficialmente supportato da flutter_local_notifications.
    //Evita l'inizializzazione per prevenire LateInitializationError.
    if (_isWindows()) {
      _supported = false;
      return;
    }

    try {
      final plugin = FlutterLocalNotificationsPlugin();

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

      await plugin.initialize(settings);
      _plugin = plugin;
      _supported = true;

      //Richiesta permessi su Android 13+ e iOS.
      try {
        await plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {}
      try {
        await plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Notifications] init error: $e');
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
    if (!_supported || _plugin == null) return;
    try {
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
      await _plugin!.show(id, title, body, details);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Notifications] show error: $e');
      }
    }
  }

  bool _isWindows() {
    try {
      //dart:io non disponibile sul web, già gestito sopra.
      //ignore: unnecessary_import
      // ignore: avoid_dynamic_calls
      return defaultTargetPlatform == TargetPlatform.windows;
    } catch (_) {
      return false;
    }
  }
}
