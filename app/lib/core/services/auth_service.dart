// ============================================================
// AuthService — gestione autenticazione e sessione utente
// ============================================================
//
// Gestisce il flusso di login/logout e il JWT token.
//
// FLUSSO DI AUTENTICAZIONE COMPLETO (quando il backend sarà pronto):
// 1. Utente inserisce URL Raspberry + email + password nel LoginScreen
// 2. AuthService.login() chiama POST /api/v1/auth/login sul backend
// 3. Il backend verifica le credenziali e risponde con un JWT token
// 4. Il token viene salvato in memoria (e in flutter_secure_storage)
// 5. ApiService.setToken() inietta il token in tutte le richieste future
// 6. Il router (go_router) redirige alla dashboard tramite redirect guard
//
// STATO ATTUALE: login con dati fake, senza http reale.
// TODO: implementare login con http + flutter_secure_storage per
//       persistere il token tra le sessioni dell'app.
//
// NOTE SU flutter_secure_storage:
//   Salva dati sensibili (tipo il JWT) nel Keychain (iOS)
//   o nel Keystore (Android). Più sicuro di SharedPreferences.
//   Aggiungilo al pubspec.yaml: flutter_secure_storage: ^9.2.2
// TODO: aggiungere flutter_secure_storage al pubspec.yaml

import 'dart:async';

import '../models/models.dart';
import 'api_service.dart';

/// Gestisce lo stato di autenticazione dell'utente corrente.
///
/// È un singleton (come ApiService) perché deve essere accessibile
/// da qualsiasi punto dell'app tramite [AuthService.instance].
///
/// In un progetto più grande si userebbe Riverpod o BLoC per la
/// gestione dello stato. Per questo progetto, Provider è sufficiente.
///
/// Esempio d'uso:
/// ```dart
/// final auth = AuthService.instance;
/// await auth.login(
///   baseUrl: 'https://xxxx.trycloudflare.com',
///   email: 'simone@gatekeeper.local',
///   password: '...',
/// );
/// print(auth.currentUser?.displayName); // 'Simone'
/// print(auth.isAdmin); // true
/// ```
class AuthService {
  // Costruttore privato per il pattern Singleton
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Stato interno ───────────────────────────────────────────────────

  /// L'utente attualmente loggato. Null se non autenticato.
  GkUser? _currentUser;

  /// Il JWT token attivo. Null se non autenticato.
  String? _token;

  // ── Getters pubblici ───────────────────────────────────────────────

  /// Restituisce l'utente loggato, o null se non autenticato.
  GkUser? get currentUser => _currentUser;

  /// True se c'è un utente loggato con token valido in memoria.
  bool get isAuthenticated => _currentUser != null && _token != null;

  /// Ruolo dell'utente corrente.
  /// Usato in tutto l'app per mostrare/nascondere sezioni UI.
  UserRole get currentRole => _currentUser?.role ?? UserRole.adult;

  /// True se l'utente corrente è amministratore.
  bool get isAdmin => currentRole == UserRole.admin;

  // ── Metodi principali ─────────────────────────────────────────────

  /// Esegue il login verso il backend GateKeeper.
  ///
  /// - [baseUrl]: URL del Raspberry tramite Cloudflare Tunnel
  ///   (es. "https://xxxx.trycloudflare.com")
  /// - [email]: email dell'account utente
  /// - [password]: password dell'account
  ///
  /// Lancia [ApiException] se le credenziali sono errate o il server
  /// non è raggiungibile.
  ///
  /// TODO: sostituire il corpo stub con chiamata HTTP reale:
  /// ```dart
  /// ApiService.instance.setBaseUrl(baseUrl);
  /// final uri = Uri.parse('$baseUrl/api/v1/auth/login');
  /// final response = await http.post(uri,
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: jsonEncode({'email': email, 'password': password}),
  /// );
  /// if (response.statusCode == 401) {
  ///   throw const ApiException(statusCode: 401, message: 'Credenziali errate');
  /// }
  /// if (response.statusCode != 200) {
  ///   throw ApiException(statusCode: response.statusCode, message: 'Errore server');
  /// }
  /// final data = jsonDecode(response.body) as Map<String, dynamic>;
  /// _token = data['access_token'] as String;
  /// ApiService.instance.setToken(_token!);
  /// _currentUser = GkUser.fromJson(data['user'] as Map<String, dynamic>);
  /// // TODO: salvare token e baseUrl in flutter_secure_storage
  /// ```
  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    // Simula latenza di rete (800ms è un tempo realistico per una chiamata locale)
    await Future.delayed(const Duration(milliseconds: 800));

    // Validazione base lato client
    if (email.trim().isEmpty || password.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'Email e password sono obbligatori',
      );
    }

    // TODO: sostituire con chiamata HTTP reale (vedi commento sopra)

    // Configura il base URL in ApiService per tutte le chiamate future
    ApiService.instance.setBaseUrl(baseUrl);

    // Simula il token JWT ricevuto dal backend
    _token = 'fake_jwt_${DateTime.now().millisecondsSinceEpoch}';
    ApiService.instance.setToken(_token!);

    // Simula l'utente ricevuto dal backend
    _currentUser = GkUser.fromJson(kFakeUsersJson.first);
  }

  /// Esegue il logout: cancella token e utente dalla memoria.
  ///
  /// TODO: aggiungere chiamata POST /api/v1/auth/logout per
  ///       invalidare il token lato server (blacklist JWT).
  /// TODO: cancellare token e baseUrl da flutter_secure_storage.
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    ApiService.instance.clearToken();
  }

  /// Tenta di ripristinare la sessione da un token salvato in precedenza.
  ///
  /// Viene chiamato in [main()] prima di [runApp()] per controllare
  /// se l'utente è già loggato da una sessione precedente.
  ///
  /// Se il token è valido: carica l'utente e il router va alla dashboard.
  /// Se il token è scaduto o assente: il router va al LoginScreen.
  ///
  /// TODO: implementare con flutter_secure_storage:
  /// ```dart
  /// const storage = FlutterSecureStorage();
  /// final token = await storage.read(key: 'gk_jwt_token');
  /// final baseUrl = await storage.read(key: 'gk_base_url');
  /// if (token == null || baseUrl == null) return; // nessuna sessione salvata
  ///
  /// ApiService.instance.setBaseUrl(baseUrl);
  /// ApiService.instance.setToken(token);
  /// _token = token;
  ///
  /// try {
  ///   // Verifica che il token sia ancora valido chiamando /users/me
  ///   _currentUser = await ApiService.instance.getMe();
  /// } on ApiException {
  ///   // Token scaduto o revocato: pulizia
  ///   await logout();
  /// }
  /// ```
  Future<void> tryRestoreSession() async {
    // TODO: implementare con flutter_secure_storage (vedi commento sopra)
    // Per ora non fa nulla: l'utente deve sempre fare login all'avvio
  }

  /// Aggiorna i dati del profilo dell'utente corrente dal server.
  ///
  /// Da chiamare dopo che l'utente modifica il proprio profilo
  /// nell'AccountScreen, così l'UI riflette subito le modifiche.
  Future<void> refreshCurrentUser() async {
    if (!isAuthenticated) return;
    _currentUser = await ApiService.instance.getMe();
  }
}
