import 'api_client.dart';
import 'dto.dart';

class InvitesApi {
  InvitesApi(this._client);
  final ApiClient _client;

  Future<InviteDto> create({
    String role = 'adult',
    String? suggestedName,
    int ttlHours = 24 * 7,
  }) async {
    final res = await _client.post('/invites', body: {
      'role': role,
      'suggested_name': suggestedName,
      'ttl_hours': ttlHours,
    });
    return InviteDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<InviteDto>> list({bool activeOnly = true}) async {
    final res = await _client.get('/invites', query: {'active_only': activeOnly});
    return (res as List).map((e) => InviteDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<InviteDto> getByToken(String token) async {
    final res = await _client.get('/invites/by-token/$token', withAuth: false);
    return InviteDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  //Accetta un invito. Restituisce token + utente neonato.
  Future<Map<String, dynamic>> accept({
    required String token,
    required String username,
    required String password,
    String? email,
  }) async {
    final res = await _client.post('/invites/accept', body: {
      'token': token,
      'username': username,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
    }, withAuth: false);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> revoke(int id) async {
    await _client.delete('/invites/$id');
  }
}
