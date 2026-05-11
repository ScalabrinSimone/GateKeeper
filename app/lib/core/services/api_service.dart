// ============================================================
// ApiService — client HTTP per le API del Raspberry Pi
// ============================================================
//
// Questo servizio è il punto di contatto tra l'app Flutter
// e il backend FastAPI che gira sul Raspberry Pi 4.
//
// STRUTTURA:
// - Gestisce il base URL (Cloudflare Tunnel) configurabile dopo il setup
// - Inietta il JWT token nell'header Authorization di ogni richiesta
// - Ogni metodo corrisponde a un endpoint REST del backend
//
// STATO ATTUALE: tutti i metodi sono stub con dati fake.
// TODO: sostituire gradualmente con chiamate HTTP reali.
//
// PER USARE HTTP REALE:
//   1. Apri pubspec.yaml
//   2. Aggiungi sotto dependencies:  http: ^1.2.1
//   3. Esegui `flutter pub get` nel terminale
//   4. Aggiungi import 'package:http/http.dart' as http;
//   5. Aggiungi import 'dart:convert'; per jsonDecode/jsonEncode
//
// TODO: aggiungere http: ^1.2.1 al pubspec.yaml

import 'dart:async';

import '../models/models.dart';

// ── Eccezioni personalizzate ───────────────────────────────────────────────

/// Eccezione lanciata quando il backend risponde con un errore HTTP.
///
/// Usala nei widget con try/catch per mostrare messaggi di errore
/// contestuali invece di far crashare l'app.
///
/// Esempio:
/// ```dart
/// try {
///   final events = await ApiService.instance.getEvents();
/// } on ApiException catch (e) {
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(e.message)),
///   );
/// }
/// ```
class ApiException implements Exception {
  /// Codice HTTP della risposta (es. 401, 404, 500).
  final int statusCode;

  /// Messaggio leggibile dall'utente.
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ── ApiService ─────────────────────────────────────────────────────────────

/// Singleton che gestisce tutte le chiamate HTTP verso il backend GateKeeper.
///
/// Il pattern Singleton garantisce che esista una sola istanza condivisa
/// nell'intera app. Si accede sempre tramite [ApiService.instance].
///
/// Ogni metodo pubblico corrisponde a uno specifico endpoint REST.
/// Nomenclatura: `verb + Resource` (es. getEvents, createObject, deleteUser).
///
/// Esempio d'uso:
/// ```dart
/// final api = ApiService.instance;
/// api.setBaseUrl('https://xxx.trycloudflare.com');
/// api.setToken('eyJhbGc...');
/// final events = await api.getEvents();
/// ```
class ApiService {
  // ── Singleton ────────────────────────────────────────────────────────
  // Il costruttore privato ApiService._() impedisce di creare nuove istanze
  // dall'esterno. Tutti usano ApiService.instance.
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Configurazione ───────────────────────────────────────────────────

  /// Base URL del backend Raspberry + Cloudflare Tunnel.
  /// Impostato dopo il primo setup dalla schermata di configurazione.
  // TODO: leggere da flutter_secure_storage al primo avvio
  String _baseUrl = 'https://YOUR_TUNNEL.trycloudflare.com';

  /// JWT token da inviare come Bearer in ogni richiesta autenticata.
  String? _token;

  /// Headers standard per tutte le richieste autenticate.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // L'header Authorization viene aggiunto solo se il token è presente.
        // In questo modo le route pubbliche (es. /auth/login) funzionano senza token.
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Setup ────────────────────────────────────────────────────────────

  /// Imposta il base URL del backend (chiamato dopo il primo setup casa).
  void setBaseUrl(String url) => _baseUrl = url;

  /// Imposta il JWT token (chiamato da AuthService dopo il login).
  void setToken(String token) => _token = token;

  /// Rimuove il token dalla memoria (chiamato al logout).
  void clearToken() => _token = null;

  /// Espone il base URL corrente (utile per debug e settings screen).
  String get baseUrl => _baseUrl;

  // ── EVENTI ───────────────────────────────────────────────────────────────
  // Endpoint backend: GET /api/v1/events

  /// Recupera la lista degli eventi rilevati dalla porta.
  ///
  /// - [limit]: quanti eventi restituire massimo (default 50).
  /// - [offset]: per la paginazione — salta i primi N eventi.
  ///
  /// TODO: sostituire il corpo con chiamata HTTP reale:
  /// ```dart
  /// final uri = Uri.parse('$_baseUrl/api/v1/events').replace(
  ///   queryParameters: {'limit': '$limit', 'offset': '$offset'},
  /// );
  /// final response = await http.get(uri, headers: _headers);
  /// _checkStatus(response); // lancia ApiException se != 200
  /// final data = jsonDecode(response.body)['events'] as List;
  /// return data.map((e) => GateEvent.fromJson(e)).toList();
  /// ```
  Future<List<GateEvent>> getEvents({int limit = 50, int offset = 0}) async {
    // Simula la latenza di rete tipica di una chiamata locale (LAN/tunnel)
    await Future.delayed(const Duration(milliseconds: 600));
    // TODO: sostituire con chiamata HTTP reale (vedi commento sopra)
    return kFakeEventsJson.map(GateEvent.fromJson).toList();
  }

  // ── OGGETTI RFID ──────────────────────────────────────────────────────
  // Endpoint backend: GET/POST/PUT/DELETE /api/v1/objects

  /// Recupera tutti gli oggetti RFID registrati nella casa.
  ///
  /// TODO: implementare con http.get — stesso pattern di getEvents
  Future<List<RfidObject>> getObjects() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: sostituire con chiamata HTTP reale
    return kFakeObjectsJson.map(RfidObject.fromJson).toList();
  }

  /// Crea un nuovo oggetto RFID nel sistema.
  ///
  /// - [object]: il nuovo oggetto da registrare.
  ///
  /// TODO: implementare con:
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('$_baseUrl/api/v1/objects'),
  ///   headers: _headers,
  ///   body: jsonEncode(object.toJson()),
  /// );
  /// _checkStatus(response);
  /// return RfidObject.fromJson(jsonDecode(response.body));
  /// ```
  Future<RfidObject> createObject(RfidObject object) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: sostituire con chiamata HTTP reale
    return object;
  }

  /// Aggiorna un oggetto RFID esistente.
  ///
  /// TODO: implementare con http.put /api/v1/objects/{rfid_tag}
  Future<RfidObject> updateObject(RfidObject object) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: sostituire con chiamata HTTP reale
    return object;
  }

  /// Elimina un oggetto RFID dal sistema.
  ///
  /// - [rfidTag]: il tag EPC dell'oggetto da eliminare.
  ///
  /// TODO: implementare con http.delete /api/v1/objects/{rfid_tag}
  Future<void> deleteObject(String rfidTag) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: sostituire con chiamata HTTP reale
  }

  // ── UTENTI ──────────────────────────────────────────────────────────────────
  // Endpoint backend: GET/POST/PUT/DELETE /api/v1/users
  // NOTA: le operazioni su altri utenti sono riservate al ruolo admin.

  /// Recupera tutti gli utenti della casa.
  ///
  /// Solo gli utenti [UserRole.admin] hanno accesso a questo endpoint.
  /// TODO: implementare con http.get /api/v1/users
  Future<List<GkUser>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: sostituire con chiamata HTTP reale
    return kFakeUsersJson.map(GkUser.fromJson).toList();
  }

  /// Recupera il profilo dell'utente correntemente loggato.
  ///
  /// TODO: implementare con http.get /api/v1/users/me
  Future<GkUser> getMe() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: sostituire con chiamata HTTP reale
    return GkUser.fromJson(kFakeUsersJson.first);
  }

  /// Crea un nuovo utente (solo admin).
  ///
  /// TODO: implementare con http.post /api/v1/users
  Future<GkUser> createUser(GkUser user) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: sostituire con chiamata HTTP reale
    return user;
  }

  /// Aggiorna un utente esistente.
  ///
  /// TODO: implementare con http.put /api/v1/users/{id}
  Future<GkUser> updateUser(GkUser user) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: sostituire con chiamata HTTP reale
    return user;
  }

  /// Elimina un utente (solo admin).
  ///
  /// - [userId]: ID dell'utente da eliminare.
  ///
  /// TODO: implementare con http.delete /api/v1/users/{id}
  Future<void> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: sostituire con chiamata HTTP reale
  }

  // ── Helper privati ────────────────────────────────────────────────────────

  // TODO: decommentare quando si aggiunge il package http reale
  // void _checkStatus(http.Response response) {
  //   if (response.statusCode >= 400) {
  //     final body = jsonDecode(response.body);
  //     throw ApiException(
  //       statusCode: response.statusCode,
  //       message: body['detail'] ?? 'Errore sconosciuto',
  //     );
  //   }
  // }
}
