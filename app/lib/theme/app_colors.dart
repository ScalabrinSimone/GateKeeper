import 'package:flutter/material.dart';

/// Palette di colori centralizzata per GateKeeper.
///
/// Questa classe raggruppa i colori base del brand così come definiti
/// nel mockup Figma e nella documentazione:
///
/// - Ink Black: #0D1117 (sfondo principale)
/// - Charcoal Blue: #41474E (pannelli, linee, testo secondario)
/// - Stormy Teal: #00767A (accento principale, CTA)
/// - Orange: #FFA400 (accento alert/warning)
/// - Lavender Blush: #F0E2E7 (accento chiaro, badge, light theme)
///
/// Nota: usare preferibilmente [Theme.of(context).colorScheme] nei widget
/// component-based. [AppColors] è utile per elementi "branded" fissi
/// (es. gradienti di background custom, hero cards, ecc.).
abstract final class AppColors {
  static const Color inkBlack = Color(0xFF0D1117);
  static const Color charcoalBlue = Color(0xFF41474E);
  static const Color stormyTeal = Color(0xFF00767A);
  static const Color orange = Color(0xFFFFA400);
  static const Color lavenderBlush = Color(0xFFF0E2E7);

  // Varianti derivate usate nel mockup scuro
  static const Color panel = Color(0xFF161B22); // card principali
  static const Color panelSoft = Color(0xFF1E242C);
  static const Color textPrimary = Color(0xFFE6EDF7);
  static const Color textMuted = Color(0xFF8B949E);

  /// Colore di testo secondario (alias per [textMuted]) per compatibilità
  /// con il codice esistente. Usato in dashboard, activity feed, ecc.
  static const Color textSecondary = textMuted;

  /// Colore "success" per stati online/presenti.
  static const Color success = Color(0xFF2ECC71); // verde brillante

  /// Colore "danger" per stati critici.
  static const Color danger = Color(0xFFE5534B); // rosso caldo

  /// Bordi e linee sottili.
  static const Color border = Color(0xFF30363D);

  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  static Color get stormyTealBright => stormyTeal.withOpacity(0.9);

  /// TODO: quando verrà introdotto il logo SVG ufficiale, aggiungere qui
  /// eventuali colori specifici derivati direttamente dal file vettoriale
  /// (es. gradienti o toni aggiuntivi) per mantenerli centralizzati.
}
