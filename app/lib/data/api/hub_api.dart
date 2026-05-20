import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_exception.dart';
import 'dto.dart';

//Endpoint dell'hub: info, status, pairing, QR, factory reset.
class HubApi {
  HubApi(this._client);
  final ApiClient _client;

  Future<HubInfoDto> info() async {
    final res = await _client.get('/hub/info', withAuth: false);
    return HubInfoDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  //Payload "QR-friendly": base_url, factory_code, house_name, paired.
  Future<HubQrDto> qr() async {
    final res = await _client.get('/hub/qr', withAuth: false);
    return HubQrDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<AuthResultDto> pair({
    required String houseName,
    required String username,
    required String password,
    required String email,
    String? factoryCode,
  }) async {
    final res = await _client.post('/hub/pair', body: {
      'house_name': houseName,
      'username': username,
      'password': password,
      'email': email,
      if (factoryCode != null && factoryCode.isNotEmpty) 'factory_code': factoryCode,
    }, withAuth: false);
    return AuthResultDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<Map<String, dynamic>> factoryReset() async {
    final res = await _client.post('/hub/factory-reset', body: {'confirm': true});
    return Map<String, dynamic>.from(res as Map);
  }

  //Verifica che un URL arbitrario punti a un hub GateKeeper valido.
  //Non tocca la configurazione globale del client: usa un client HTTP
  //temporaneo con timeout breve così la UI può confermare prima di
  //salvare l'URL come baseUrl ufficiale.
  static Future<HubInfoDto> probe(
    String baseUrl, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final cleaned = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty || !(cleaned.startsWith('http://') || cleaned.startsWith('https://'))) {
      throw ApiException('URL non valido', code: 'invalid_url');
    }
    final client = http.Client();
    try {
      final res = await client
          .get(Uri.parse('$cleaned/hub/info'), headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final body = jsonDecode(res.body);
          if (body is Map) {
            return HubInfoDto.fromJson(Map<String, dynamic>.from(body));
          }
        } catch (_) {}
        throw ApiException('Risposta non valida dall\'hub.', code: 'invalid_response');
      }
      throw ApiException(
        'L\'hub ha risposto con HTTP ${res.statusCode}.',
        statusCode: res.statusCode,
      );
    } on TimeoutException {
      throw ApiException(
        'Timeout: nessuna risposta da $cleaned.',
        code: 'timeout',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Errore di rete: $e', code: 'network');
    } finally {
      client.close();
    }
  }
}
