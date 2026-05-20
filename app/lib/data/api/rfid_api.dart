import 'api_client.dart';
import 'dto.dart';

//Endpoint del lettore RFID.
//- /rfid/scan/latest: ultimo tag sconosciuto rilevato (per UX "avvicina il tag").
//- /rfid/scan: lista completa.
//- DELETE /rfid/scan/{tag}: rimuove un tag dal buffer una volta associato.
class RfidApi {
  RfidApi(this._client);
  final ApiClient _client;

  Future<ScannedTagDto?> latest() async {
    final res = await _client.get('/rfid/scan/latest');
    if (res == null) return null;
    if (res is Map) return ScannedTagDto.fromJson(Map<String, dynamic>.from(res));
    return null;
  }

  Future<List<ScannedTagDto>> list() async {
    final res = await _client.get('/rfid/scan');
    return (res as List)
        .map((e) => ScannedTagDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> consume(String tag) async {
    await _client.delete('/rfid/scan/${Uri.encodeComponent(tag)}');
  }
}
