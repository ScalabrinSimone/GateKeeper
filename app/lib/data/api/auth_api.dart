import 'api_client.dart';
import 'dto.dart';

//Endpoint di autenticazione.
class AuthApi {
  AuthApi(this._client);
  final ApiClient _client;

  Future<AuthResultDto> login({required String identifier, required String password}) async {
    final res = await _client.post('/auth/login', body: {
      'identifier': identifier,
      'password': password,
    }, withAuth: false);
    return AuthResultDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<UserDto> me() async {
    final res = await _client.get('/auth/me');
    return UserDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {
      //Best-effort: il logout lato server è solo un ack, può fallire.
    }
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', body: {'email': email}, withAuth: false);
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _client.post('/auth/reset-password', body: {
      'token': token,
      'new_password': newPassword,
    }, withAuth: false);
  }
}
