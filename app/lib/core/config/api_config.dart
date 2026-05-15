import 'package:shared_preferences/shared_preferences.dart';

//Configurazione runtime dell'endpoint API dell'hub GateKeeper.
//
//Nota architettura:
//- NON esiste un valore di default funzionante (niente loopback "di test").
//- Finché l'utente non fa pairing (LAN tramite discovery) o non inserisce un
//  URL manuale (tipicamente un tunnel remoto), `baseUrl` è null e ogni
//  chiamata HTTP fallisce in modo controllato così da forzare il flow di
//  onboarding o di riconfigurazione.
//- Il valore viene persistito su `shared_preferences` per ripristinarlo
//  automaticamente all'avvio successivo.
class ApiConfig {
  ApiConfig._();

  static const String _kBaseUrl = 'gk.api.base_url';
  static const String _kRecent = 'gk.api.recent_hubs';

  static String? _current;

  //Restituisce la base URL corrente (senza trailing slash) o null se non
  //ancora configurata. Le API client lo usano per costruire le richieste:
  //quando è null, lanciano un errore di "hub non configurato".
  static String? get baseUrl => _current;

  //Indica se l'hub è stato configurato almeno una volta su questo dispositivo.
  static bool get isConfigured => _current != null && _current!.isNotEmpty;

  //Carica la base URL dalle preferenze.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kBaseUrl);
    if (saved != null && saved.isNotEmpty) {
      _current = saved.replaceAll(RegExp(r'/+$'), '');
    } else {
      _current = null;
    }
  }

  //Aggiorna e salva la base URL (chiamata dopo pairing/discovery o quando
  //l'utente configura un tunnel remoto).
  static Future<void> setBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty) return;
    _current = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, cleaned);
    await pushRecent(cleaned);
  }

  //Ripristina al "non configurato" (es. dopo logout di un dispositivo che
  //vuole tornare al flow di pairing senza ricordare l'URL precedente).
  static Future<void> reset() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBaseUrl);
  }

  //Cronologia degli ultimi hub usati (max 5), utile per riproporre
  //rapidamente l'ultimo URL nella schermata di discovery.
  static Future<List<String>> recentHubs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kRecent) ?? const <String>[];
  }

  static Future<void> pushRecent(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kRecent) ?? <String>[];
    list.removeWhere((e) => e == cleaned);
    list.insert(0, cleaned);
    while (list.length > 5) {
      list.removeLast();
    }
    await prefs.setStringList(_kRecent, list);
  }

  //Rimuove una singola entry dalla cronologia degli hub recenti.
  //Usato quando l'utente fa swipe / tap su "rimuovi" nella lista.
  static Future<void> removeRecent(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kRecent) ?? <String>[];
    list.removeWhere((e) => e == cleaned);
    await prefs.setStringList(_kRecent, list);
  }

  static Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecent);
  }
}
