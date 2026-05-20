import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Controller di impostazioni globali (tema + lingua) basato su ChangeNotifier.
//Persiste le scelte dell'utente tramite SharedPreferences.
class SettingsController extends ChangeNotifier {
  SettingsController({ThemeMode initialTheme = ThemeMode.dark, Locale initialLocale = const Locale('it')})
      : _themeMode = initialTheme,
        _locale = initialLocale;

  static const _kThemeKey = 'gk.theme';
  static const _kLocaleKey = 'gk.locale';
  static const _kPushKey = 'gk.notifications.push_enabled';
  static const _kRemoteUrlKey = 'gk.remote.tunnel_url';

  ThemeMode _themeMode;
  Locale _locale;
  bool _pushEnabled = true;
  String? _remoteTunnelUrl;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get pushEnabled => _pushEnabled;
  //URL del tunnel remoto memorizzato (es. Cloudflare Tunnel). Non è
  //applicato automaticamente: è una scorciatoia che l'utente conferma
  //esplicitamente per cambiare hub.
  String? get remoteTunnelUrl => _remoteTunnelUrl;

  //Carica le preferenze persistite.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final theme = _prefs!.getString(_kThemeKey);
    final lang = _prefs!.getString(_kLocaleKey);

    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    }
    if (lang == 'it' || lang == 'en') {
      _locale = Locale(lang!);
    }
    _pushEnabled = _prefs!.getBool(_kPushKey) ?? true;
    _remoteTunnelUrl = _prefs!.getString(_kRemoteUrlKey);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _prefs?.setString(_kThemeKey, isDark ? 'dark' : 'light');
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _prefs?.setString(_kLocaleKey, locale.languageCode);
  }

  Future<void> setPushEnabled(bool value) async {
    _pushEnabled = value;
    notifyListeners();
    await _prefs?.setBool(_kPushKey, value);
  }

  Future<void> setRemoteTunnelUrl(String? url) async {
    final cleaned = (url ?? '').trim();
    _remoteTunnelUrl = cleaned.isEmpty ? null : cleaned;
    notifyListeners();
    if (_remoteTunnelUrl == null) {
      await _prefs?.remove(_kRemoteUrlKey);
    } else {
      await _prefs?.setString(_kRemoteUrlKey, _remoteTunnelUrl!);
    }
  }
}
