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

  ThemeMode _themeMode;
  Locale _locale;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isDark => _themeMode == ThemeMode.dark;

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
}
