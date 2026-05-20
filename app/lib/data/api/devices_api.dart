import 'api_client.dart';
import 'dto.dart';

class DevicesApi {
  DevicesApi(this._client);
  final ApiClient _client;

  Future<List<DeviceDto>> list() async {
    final res = await _client.get('/devices');
    return (res as List).map((e) => DeviceDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<DeviceDto> create({
    required String name,
    String? rfidTag,
    String category = 'other',
    bool isEssential = false,
  }) async {
    final res = await _client.post('/devices', body: {
      'name': name,
      if (rfidTag != null && rfidTag.isNotEmpty) 'rfid_tag': rfidTag,
      'category': category,
      'is_essential': isEssential,
    });
    return DeviceDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<DeviceDto> update(int id, Map<String, dynamic> fields) async {
    final res = await _client.put('/devices/$id', body: fields);
    return DeviceDto.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(int id) async {
    await _client.delete('/devices/$id');
  }
}
