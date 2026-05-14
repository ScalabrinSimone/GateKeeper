import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_exception.dart';

//Client HTTP minimale costruito sopra package:http.
//Caratteristiche:
//- timeout configurabile,
//- gestione automatica del Bearer token,
//- parsing JSON con error handling unificato (ApiException),
//- helper get/post/put/delete.
class ApiClient {
  ApiClient({Duration timeout = const Duration(seconds: 10)})
      : _timeout = timeout,
        _http = http.Client();

  //Costruttore alternativo per i test (inietta http client custom).
  ApiClient.withHttp(http.Client client, {Duration timeout = const Duration(seconds: 10)})
      : _timeout = timeout,
        _http = client;

  final http.Client _http;
  final Duration _timeout;
  String? _token;

  //Imposta o rimuove il bearer token usato per le chiamate autenticate.
  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.baseUrl;
    final url = '$base$path';
    final uri = Uri.parse(url);
    if (query == null || query.isEmpty) return uri;
    final filtered = <String, String>{};
    query.forEach((k, v) {
      if (v == null) return;
      filtered[k] = v.toString();
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...filtered});
  }

  Map<String, String> _headers({bool withAuth = true, bool jsonBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) headers['Content-Type'] = 'application/json';
    if (withAuth && _token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Timeout di rete: nessuna risposta dall\'hub.');
    } catch (e) {
      throw ApiException('Errore di rete: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    }

    String message = 'Errore HTTP ${res.statusCode}';
    String? code;
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final detail = body['detail'] ?? body['message'];
        if (detail is String) message = detail;
        if (body['code'] is String) code = body['code'];
      }
    } catch (_) {}
    throw ApiException(message, statusCode: res.statusCode, code: code);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool withAuth = true}) {
    return _send(() => _http.get(_uri(path, query), headers: _headers(withAuth: withAuth)));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send(() => _http.post(
          _uri(path),
          headers: _headers(withAuth: withAuth, jsonBody: true),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool withAuth = true}) {
    return _send(() => _http.put(
          _uri(path),
          headers: _headers(withAuth: withAuth, jsonBody: true),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> delete(String path, {bool withAuth = true}) {
    return _send(() => _http.delete(_uri(path), headers: _headers(withAuth: withAuth)));
  }

  void close() => _http.close();
}
