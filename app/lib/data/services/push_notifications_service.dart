import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../core/platform/platform_info.dart';
import '../api/api_exception.dart';
import '../gatekeeper_api.dart';

//Servizio "scaffolding" per le notifiche push remote (FCM/APNs).
//Nota: il pacchetto Firebase non è stato aggiunto alle dipendenze: per
//abilitarlo serve seguire le istruzioni nel README dell'app (sezione
//"Notifiche push"). Questo servizio espone l'interfaccia che la UI usa per
//chiedere il permesso, ottenere il token e inviarlo al backend. Le funzioni
//che dipendono da Firebase sono stub che ritornano sempre `false`/`null`
//finché il setup completo non è stato fatto.
class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();

  bool _initialized = false;
  String? _token;
  String? get currentToken => _token;

  //Indica se la piattaforma supporta in linea di principio le push.
  bool get isSupportedPlatform {
    if (PlatformInfo.isMobile) return true;
    if (PlatformInfo.isWeb) return true;
    return false;
  }

  String get _platformName {
    if (PlatformInfo.isWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'desktop';
  }

  //Inizializza il sottosistema push:
  //- se Firebase è disponibile, richiede il permesso e si registra,
  //- altrimenti non fa nulla (il toggle UI lo segnalerà).
  Future<bool> initialize() async {
    if (_initialized) return _token != null;
    _initialized = true;
    if (!isSupportedPlatform) return false;

    final token = await _tryGetFcmToken();
    if (token == null) return false;
    _token = token;

    //Best-effort: invia il token al backend se l'utente è loggato.
    try {
      await GateKeeperApi.instance.users
          .registerPushToken(token: token, platform: _platformName);
    } on ApiException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Push] backend register fallito: ${e.message}');
      }
    } catch (_) {}
    return true;
  }

  //Disattiva la registrazione del token su questo dispositivo.
  Future<void> revoke() async {
    final token = _token;
    if (token == null) return;
    try {
      await GateKeeperApi.instance.users.unregisterPushToken(token);
    } catch (_) {}
    _token = null;
  }

  //Stub: ritorna null finché Firebase non è configurato.
  //Quando viene aggiunto il pacchetto `firebase_messaging`, basta
  //sostituire il corpo con il `getToken()` reale.
  Future<String?> _tryGetFcmToken() async {
    //TODO: integrare firebase_messaging quando i config Firebase saranno
    //forniti. Il resto del flusso (registrazione backend, settings UI) è
    //già pronto.
    return null;
  }
}
