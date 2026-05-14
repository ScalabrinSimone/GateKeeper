import 'package:shared_preferences/shared_preferences.dart';

//Configurazione runtime dell'endpoint API.
//Default: http://127.0.0.1:8000 (utile in dev).
//Dopo il pairing, l'app salva l'IP dell'hub trovato via discovery.
class ApiConfig {
  ApiConfig._();

  static const String _kBaseUrl = 'gk.api.base_url';

  //URL di default. In dev punta al backend locale; in produzione viene
  //sovrascritto dalla discovery del Raspberry.
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  static String _current = defaultBaseUrl;

  //Restituisce la base URL corrente (senza trailing slash).
  static String get baseUrl => _current;

  //Carica la base URL dalle preferenze.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kBaseUrl);
    if (saved != null && saved.isNotEmpty) {
      _current = saved;
    }
  }

  //Aggiorna e salva la base URL (chiamata dopo pairing/discovery).
  static Future<void> setBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    _current = cleaned.isEmpty ? defaultBaseUrl : cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, _current);
  }

  //Ripristina al default (es. dopo logout o factory reset).
  static Future<void> reset() async {
    _current = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBaseUrl);
  }
}
