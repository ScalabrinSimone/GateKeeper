import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Controller singleton per l'avatar dell'utente corrente.
//Carica e persiste il percorso locale dell'immagine profilo in SharedPreferences
//e notifica tutti i listener (sidebar, account page, ecc.) al cambio.
class AvatarController extends ChangeNotifier {
  AvatarController._();

  static final AvatarController instance = AvatarController._();

  static const _kPrefPrefix = 'gk.avatar.path.';

  String? _avatarPath;
  String? _userId;

  //Percorso dell'immagine corrente (null = usa iniziali).
  String? get avatarPath => _avatarPath;

  //Carica l'avatar salvato per l'userId specificato.
  Future<void> loadForUser(String userId) async {
    if (_userId == userId) return;
    _userId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('$_kPrefPrefix$userId');
      _avatarPath = saved;
      notifyListeners();
    } catch (_) {}
  }

  //Aggiorna l'avatar e lo persiste.
  Future<void> setAvatar(String userId, String path) async {
    _userId = userId;
    _avatarPath = path;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_kPrefPrefix$userId', path);
    } catch (_) {}
  }

  //Rimuove l'avatar e cancella da SharedPreferences.
  Future<void> removeAvatar(String userId) async {
    _userId = userId;
    _avatarPath = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_kPrefPrefix$userId');
    } catch (_) {}
  }

  //Resetta al logout: solo la cache in memoria.
  void clear() {
    _avatarPath = null;
    _userId = null;
    notifyListeners();
  }

  //Factory reset: dissocia TUTTI gli avatar salvati su questo dispositivo.
  //I file immagine NON vengono eliminati; vengono solo rimossi i riferimenti in SharedPreferences.
  Future<void> clearAllForFactoryReset() async {
    _avatarPath = null;
    _userId = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_kPrefPrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
