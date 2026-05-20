import 'api_client.dart';
import 'dto.dart';

class LogsApi {
  LogsApi(this._client);
  final ApiClient _client;

  Future<List<LogDto>> list({int? userId, int? deviceId, String? action}) async {
    final res = await _client.get('/logs', query: {
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (action != null) 'action': action,
    });
    return (res as List).map((e) => LogDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
