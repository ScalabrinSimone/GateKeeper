import 'package:flutter/material.dart';

/// Provider che gestisce il tema dell'app (dark / light).
///
/// Estende [ChangeNotifier] così tutti i widget che ascoltano questo
/// provider si ricostruiscono automaticamente quando il tema cambia.
///
/// Utilizzo:
/// ```dart
/// // Leggere il tema corrente:
/// final isDark = context.watch<ThemeProvider>().isDark;
///
/// // Cambiare tema:
/// context.read<ThemeProvider>().toggle();
/// ```
///
/// TODO: persistere la preferenza con SharedPreferences o
/// flutter_secure_storage per ricordare la scelta al riavvio.
class ThemeProvider extends ChangeNotifier {
  // Inizia in dark mode (tema principale del progetto)
  bool _isDark = true;

  /// `true` = dark mode, `false` = light mode.
  bool get isDark => _isDark;

  /// Alterna tra dark e light mode e notifica i listener.
  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  /// Imposta un valore specifico (utile dai settings).
  void setDark(bool value) {
    if (_isDark == value) return; // nessun cambiamento, non notificare
    _isDark = value;
    notifyListeners();
  }
}
