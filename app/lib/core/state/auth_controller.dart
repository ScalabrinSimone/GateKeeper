import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/api/api_exception.dart';
import '../../data/api/dto.dart';
import '../../data/gatekeeper_api.dart';
import '../../data/services/event_polling_service.dart';
import '../../data/services/push_notifications_service.dart';
import '../config/api_config.dart';
import '../storage/secure_storage.dart';

//Stato di sessione dell'app.
enum AuthStage {
  //Stato iniziale: sto verificando token + hub.
  loading,
  //Hub non accoppiato: bisogna mostrare il flow di pairing.
  needsPairing,
  //Hub accoppiato ma utente non loggato.
  needsLogin,
  //Utente loggato ma email non ancora verificata.
  needsEmailVerification,
  //Utente loggato, app pronta.
  authenticated,
  //Hub non raggiungibile: offline / errore di rete.
  offline,
}

//Controller di autenticazione + pairing.
//Esegue il bootstrap (carica config, valida token, verifica hub) e notifica
//i cambi di stato al router via ChangeNotifier.
//Esposto anche come `AuthController.instance` per evitare prop drilling
//nelle pagine "deep" (es. objects/members) che hanno bisogno solo dello
//user corrente per controlli di permesso. Le pagine entry-point (auth/onboarding)
//continuano a riceverlo via costruttore.
class AuthController extends ChangeNotifier {
  AuthController({GateKeeperApi? api}) : _api = api ?? GateKeeperApi.instance {
    _instance = this;
  }

  static AuthController? _instance;
  static AuthController get instance {
    final v = _instance;
    if (v == null) {
      throw StateError('AuthController non inizializzato.');
    }
    return v;
  }

  static const _kTokenKey = 'gk.auth.token';

  final GateKeeperApi _api;

  AuthStage _stage = AuthStage.loading;
  UserDto? _user;
  HubInfoDto? _hubInfo;
  String? _lastError;

  AuthStage get stage => _stage;
  UserDto? get user => _user;
  HubInfoDto? get hubInfo => _hubInfo;
  String? get lastError => _lastError;

  bool get isAdmin => _user?.role == 'admin';
  bool get isAuthenticated => _stage == AuthStage.authenticated && _user != null;

  //Bootstrap iniziale: carica config, valida token, verifica stato hub.
  Future<void> bootstrap() async {
    _stage = AuthStage.loading;
    notifyListeners();

    await ApiConfig.load();

    //Se non c'è un hub configurato vado direttamente al flow di pairing.
    if (!ApiConfig.isConfigured) {
      _user = null;
      _hubInfo = null;
      _api.setToken(null);
      await SecureStorage.delete(_kTokenKey);
      _stage = AuthStage.needsPairing;
      notifyListeners();
      return;
    }

    //Recupero un eventuale token salvato.
    final saved = await SecureStorage.read(_kTokenKey);
    if (saved != null && saved.isNotEmpty) {
      _api.setToken(saved);
    }

    //Controllo lo stato dell'hub.
    HubInfoDto? hub;
    try {
      hub = await _api.hub.info();
      _hubInfo = hub;
    } on ApiException catch (e) {
      _lastError = e.message;
      _stage = AuthStage.offline;
      notifyListeners();
      return;
    } catch (e) {
      _lastError = e.toString();
      _stage = AuthStage.offline;
      notifyListeners();
      return;
    }

    if (!hub.paired) {
      //Non c'è un admin: serve il pairing.
      _user = null;
      _api.setToken(null);
      await SecureStorage.delete(_kTokenKey);
      _stage = AuthStage.needsPairing;
      notifyListeners();
      return;
    }

    //Hub paired: provo a recuperare l'utente del token.
    if (_api.token != null) {
      try {
        final me = await _api.auth.me();
        _user = me;
        // Se email_verified è esplicitamente false, blocca prima della dashboard.
        if (me.emailVerified == false) {
          _stage = AuthStage.needsEmailVerification;
        } else {
          _stage = AuthStage.authenticated;
          //Inizializzazione best-effort delle push: se Firebase non è
          //configurato il servizio ritorna false senza errori.
          unawaited(PushNotificationsService.instance.initialize());
          EventPollingService.instance.start();
        }
        notifyListeners();
        return;
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          _api.setToken(null);
          await SecureStorage.delete(_kTokenKey);
        }
      } catch (_) {
        //Errore generico: ricado in login per sicurezza.
      }
    }

    _stage = AuthStage.needsLogin;
    notifyListeners();
  }

  //Tenta un login. In caso di successo, persiste token e passa a authenticated
  //oppure a needsEmailVerification se l'email non è ancora verificata.
  Future<void> login({required String identifier, required String password}) async {
    _lastError = null;
    final res = await _api.auth.login(identifier: identifier, password: password);
    _api.setToken(res.token);
    await SecureStorage.write(_kTokenKey, res.token);
    _user = res.user;
    if (res.user.emailVerified == false) {
      _stage = AuthStage.needsEmailVerification;
    } else {
      _stage = AuthStage.authenticated;
      unawaited(PushNotificationsService.instance.initialize());
      EventPollingService.instance.start();
      //Aggiorna la posizione dell'utente a "inside" al login.
      unawaited(_updateCurrentLocation('inside'));
    }
    notifyListeners();
  }

  //Pairing iniziale: crea admin + marca hub paired.
  Future<void> pairAndLogin({
    required String houseName,
    required String username,
    required String password,
    required String email,
    String? factoryCode,
  }) async {
    _lastError = null;
    final res = await _api.hub.pair(
      houseName: houseName,
      username: username,
      password: password,
      email: email,
      factoryCode: factoryCode,
    );
    _api.setToken(res.token);
    await SecureStorage.write(_kTokenKey, res.token);
    _user = res.user;
    //Aggiorna info hub locali.
    _hubInfo = HubInfoDto(
      paired: true,
      requiresFactoryCode: false,
      houseName: houseName,
    );
    if (res.user.emailVerified == false) {
      _stage = AuthStage.needsEmailVerification;
    } else {
      _stage = AuthStage.authenticated;
      unawaited(PushNotificationsService.instance.initialize());
      EventPollingService.instance.start();
    }
    notifyListeners();
  }

  //Sostituisce baseUrl (post-discovery o config manuale) e re-bootstrap.
  Future<void> useBaseUrl(String baseUrl) async {
    await ApiConfig.setBaseUrl(baseUrl);
    await bootstrap();
  }

  /// Ricarica i dati dell'utente corrente dal server e notifica i listener.
  /// Se l'email risulta verificata, avanza lo stage ad [authenticated].
  Future<void> refreshUser() async {
    try {
      final updated = await _api.auth.me();
      _user = updated;
      if (_stage == AuthStage.needsEmailVerification && updated.emailVerified != false) {
        _stage = AuthStage.authenticated;
        unawaited(PushNotificationsService.instance.initialize());
        EventPollingService.instance.start();
      }
      notifyListeners();
    } catch (_) {
      // Ignora errori di rete: i dati locali restano invariati.
    }
  }

  //"Esci dalla casa": rimuove la configurazione hub di questo dispositivo
  //(base URL + token + cache utente) ma NON tocca i dati lato Raspberry.
  //Dopo questa operazione l'app torna in stato `needsPairing` e l'utente
  //deve riscansionare un hub o inserire un URL remoto.
  Future<void> leaveHome() async {
    EventPollingService.instance.stop();
    try {
      await _api.auth.logout();
    } catch (_) {
      //best-effort, ignoriamo errori di rete.
    }
    _api.setToken(null);
    await SecureStorage.delete(_kTokenKey);
    await ApiConfig.reset();
    _user = null;
    _hubInfo = null;
    _stage = AuthStage.needsPairing;
    notifyListeners();
  }
  /// Elimina il proprio account dal server ("lascia la casa" con cancellazione).
  /// Se l'utente è l'ultimo admin, il backend esegue un factory reset completo.
  /// Restituisce [true] se è stato eseguito un factory reset.
  Future<bool> deleteAccount() async {
    bool factoryReset = false;
    try {
      factoryReset = await _api.auth.deleteMe();
    } catch (_) {
      rethrow;
    }
    _api.setToken(null);
    await SecureStorage.delete(_kTokenKey);
    await ApiConfig.reset();
    _user = null;
    _hubInfo = factoryReset ? const HubInfoDto(paired: false, requiresFactoryCode: true) : null;
    _stage = AuthStage.needsPairing;
    notifyListeners();
    return factoryReset;
  }
  //Logout: cancella token e torna a login.
  Future<void> logout() async {
    EventPollingService.instance.stop();
    //Aggiorna la posizione a "unknown" prima di fare logout.
    try {
      await _updateCurrentLocation('unknown');
    } catch (_) {}
    try {
      await _api.auth.logout();
    } catch (_) {}
    _api.setToken(null);
    await SecureStorage.delete(_kTokenKey);
    _user = null;
    //Se l'hub è ancora accoppiato, andiamo a "needsLogin", altrimenti pairing.
    _stage = (_hubInfo?.paired ?? false) ? AuthStage.needsLogin : AuthStage.needsPairing;
    notifyListeners();
  }

  //Aggiorna la current_location dell'utente loggato tramite l'API.
  Future<void> _updateCurrentLocation(String location) async {
    final uid = _user?.id;
    if (uid == null) return;
    try {
      await _api.users.update(uid, {'current_location': location});
    } catch (_) {
      //Best-effort: non blocca il flusso.
    }
  }

  //Factory reset (solo admin): svuota tutto e torna a pairing.
  Future<void> factoryReset() async {
    if (!isAdmin) throw StateError('Solo l\'admin può eseguire il factory reset.');
    await _api.hub.factoryReset();
    _api.setToken(null);
    await SecureStorage.delete(_kTokenKey);
    _user = null;
    _hubInfo = const HubInfoDto(paired: false, requiresFactoryCode: true);
    _stage = AuthStage.needsPairing;
    notifyListeners();
  }

  //Aggiorna utente in cache (es. dopo edit profilo).
  void setUser(UserDto user) {
    _user = user;
    notifyListeners();
  }
}
