import 'api_client.dart';
import 'dto.dart';

class EventsApi {
  EventsApi(this._client);
  final ApiClient _client;

  Future<List<EventDto>> list({int? userId, String? eventType}) async {
    final res = await _client.get('/events', query: {
      if (userId != null) 'user_id': userId,
      if (eventType != null) 'event_type': eventType,
    });
    return (res as List).map((e) => EventDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
