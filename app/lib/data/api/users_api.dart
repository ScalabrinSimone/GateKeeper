import 'api_client.dart';
import 'dto.dart';

class UsersApi {
  UsersApi(this._client);
  final ApiClient _client;

  Future<List<UserDto>> list() async {
    final res = await _client.get('/users');
    return (res as List).map((e) => UserDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<UserDto> getById(int id) async {
    final res = await _client.get('/users/$id');
    return UserDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<UserDto> update(int id, Map<String, dynamic> fields) async {
    final res = await _client.put('/users/$id', body: fields);
    return UserDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  //Aggiorna i permessi granulari di un utente. Solo admin.
  Future<UserDto> updatePermissions(int id, Map<String, bool> permissions) async {
    final res = await _client.put('/users/$id/permissions', body: {
      'permissions': permissions,
    });
    return UserDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(int id) async {
    await _client.delete('/users/$id');
  }

  //Registra un push token per l'utente loggato (FCM/APNs).
  Future<void> registerPushToken({required String token, String platform = 'unknown'}) async {
    await _client.post('/users/me/push-token', body: {
      'token': token,
      'platform': platform,
    });
  }

  //Rimuove un push token registrato (logout di un dispositivo).
  Future<void> unregisterPushToken(String token) async {
    await _client.delete('/users/me/push-token?token=${Uri.encodeQueryComponent(token)}');
  }
}
