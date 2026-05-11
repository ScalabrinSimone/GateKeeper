import 'package:flutter/material.dart';

/// Provider che gestisce la lingua dell'app.
///
/// Lingue supportate: Italiano (it) e Inglese (en).
/// La lingua di default è l'italiano.
///
/// Utilizzo:
/// ```dart
/// // Leggere la locale corrente:
/// final locale = context.watch<LocaleProvider>().locale;
///
/// // Cambiare lingua:
/// context.read<LocaleProvider>().setLocale(const Locale('en'));
///
/// // Toggle rapido it ↔ en:
/// context.read<LocaleProvider>().toggle();
/// ```
///
/// TODO: persistere la preferenza con SharedPreferences per ricordare
/// la lingua scelta al prossimo avvio dell'app.
class LocaleProvider extends ChangeNotifier {
  // Default: italiano
  Locale _locale = const Locale('it');

  /// Locale attuale dell'app.
  Locale get locale => _locale;

  /// `true` se la lingua corrente è l'italiano.
  bool get isItalian => _locale.languageCode == 'it';

  /// Alterna tra italiano e inglese.
  void toggle() {
    _locale = isItalian ? const Locale('en') : const Locale('it');
    notifyListeners();
  }

  /// Imposta una locale specifica tra quelle supportate.
  ///
  /// Parametri:
  /// - [locale]: la nuova [Locale] da applicare
  ///
  /// Se la locale passata non è supportata ('it' o 'en'),
  /// il metodo non fa nulla.
  void setLocale(Locale locale) {
    const supported = ['it', 'en'];
    if (!supported.contains(locale.languageCode)) return;
    if (_locale == locale) return; // già impostata, non notificare
    _locale = locale;
    notifyListeners();
  }
}
