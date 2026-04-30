import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Temi globali dell'app GateKeeper.
///
/// Contiene due [ThemeData] completi:
/// - [darkTheme]: tema scuro (default, principale)
/// - [lightTheme]: tema chiaro (variante chiara per testare la UI)
///
/// Entrambi usano Material 3 con la stessa palette brand (Stormy Teal + Orange)
/// definita in [AppColors]. I widget che hardcodano i colori di
/// [AppColors] vedranno sempre il look "mockup" scuro; per widget realmente
/// theme-aware è meglio usare `Theme.of(context).colorScheme.*`.
class AppTheme {
  AppTheme._();

  // ── Dark Theme (mockup principale) ─────────────────────────────────────

  /// Tema scuro di riferimento: sfondo Ink Black, pannelli Charcoal,
  /// accenti Stormy Teal / Orange, testi chiari.
  static ThemeData get darkTheme {
    // Costruiamo un ColorScheme coerente partendo dal colore brand teal.
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.stormyTeal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.stormyTeal,
      secondary: AppColors.orange,
      background: AppColors.inkBlack,
      surface: AppColors.panel,
      onSurface: AppColors.textPrimary,
      onPrimary: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,

      // Lo sfondo principale dell'app (Scaffold, Shell) riprende il mockup
      // con il gradiente molto scuro. Per mantenere la flessibilità usiamo
      // comunque una tinta piatta vicina.
      scaffoldBackgroundColor: AppColors.inkBlack,
      fontFamily: AppTextStyles.fontFamily,

      cardColor: AppColors.panel,
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme: _inputTheme(
        fill: AppColors.panelSoft,
        border: AppColors.border,
        focus: AppColors.stormyTealBright,
        hint: AppColors.textMuted,
      ),

      dialogBackgroundColor: AppColors.panel,
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 8,
      ),
    );
  }

  // ── Light Theme (variante chiara sperimentale) ─────────────────────────

  /// Tema chiaro: sfondo Lavender Blush, pannelli chiari, testo Ink Black.
  ///
  /// La palette di base rimane la stessa (Stormy Teal + Orange) ma con
  /// contrasti invertiti per testare la leggibilità in ambienti molto luminosi.
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.stormyTeal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.stormyTeal,
      secondary: AppColors.orange,
      background: AppColors.lavenderBlush,
      surface: Colors.white,
      onSurface: AppColors.inkBlack,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,

      // Lo sfondo generale passa a Lavender Blush per staccare dalle card
      // bianche e mantenere un minimo di "brand" anche in light mode.
      scaffoldBackgroundColor: AppColors.lavenderBlush,
      fontFamily: AppTextStyles.fontFamily,

      cardColor: Colors.white,
      dividerColor: AppColors.charcoalBlue.withOpacity(0.12),
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme: _inputTheme(
        fill: Colors.white,
        border: AppColors.charcoalBlue.withOpacity(0.18),
        focus: AppColors.stormyTeal,
        hint: AppColors.charcoalBlue.withOpacity(0.6),
      ),

      dialogBackgroundColor: Colors.white,
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.charcoalBlue.withOpacity(0.16)),
        ),
        elevation: 6,
      ),
    );
  }

  // ── Helper privato ─────────────────────────────────────────────────────

  /// Costruisce un [InputDecorationTheme] consistente per entrambi i temi.
  ///
  /// Parametri:
  /// - [fill]: colore di sfondo dell'input
  /// - [border]: colore bordo a riposo
  /// - [focus]: colore bordo quando l'input ha il focus
  /// - [hint]: colore del testo placeholder
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color focus,
    required Color hint,
  }) {
    final shape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: border),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: hint),
      border: shape,
      enabledBorder: shape,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: focus),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
