import 'api_client.dart';
import 'dto.dart';

//Endpoint dell'hub: info, status, pairing, factory reset.
class HubApi {
  HubApi(this._client);
  final ApiClient _client;

  Future<HubInfoDto> info() async {
    final res = await _client.get('/hub/info', withAuth: false);
    return HubInfoDto.fromJson(Map<String, dynamic>.from(res as Map));
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
}
