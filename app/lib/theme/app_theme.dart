import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Temi globali dell'app GateKeeper.
///
/// Contiene due [ThemeData] completi:
/// - [darkTheme]: tema scuro (default, principale)
/// - [lightTheme]: tema chiaro (Lavender Blush surfaces + Ink Black text)
///
/// Entrambi usano Material 3 con la stessa palette brand (teal + orange).
/// I widget che hardcodano [AppColors] vedranno sempre i colori dark;
/// per widget theme-aware usare [AppThemeColors.of(context)].
abstract final class AppTheme {
  // ── Dark Theme ─────────────────────────────────────────────────────────

  /// Tema scuro: sfondo Ink Black, superfici Navy, testo bianco.
  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.stormyTeal,
      brightness: Brightness.dark,
    ).copyWith(
      primary:    AppColors.stormyTeal,
      secondary:  AppColors.orange,
      surface:    AppColors.panel,
      onSurface:  AppColors.textPrimary,
      onPrimary:  AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.inkBlack,
      fontFamily: AppTextStyles.fontFamily,
      cardColor: AppColors.panel,
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.panelSoft,
        border: AppColors.border,
        focus: AppColors.stormyTealBright,
        hint: AppColors.textMuted,
      ),
      // Popup / dialog background
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

  // ── Light Theme ────────────────────────────────────────────────────────

  /// Tema chiaro: sfondo Lavender Blush, superfici bianche, testo Ink Black.
  ///
  /// Mantiene la stessa palette brand (teal CTA, orange stato) per coerenza.
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.stormyTeal,
      brightness: Brightness.light,
    ).copyWith(
      primary:    AppColorsLight.stormyTeal,
      secondary:  AppColorsLight.orange,
      surface:    AppColorsLight.panel,
      onSurface:  AppColorsLight.textPrimary,
      onPrimary:  AppColorsLight.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColorsLight.inkBlack, // Lavender Blush
      fontFamily: AppTextStyles.fontFamily,
      cardColor: AppColorsLight.panel,
      dividerColor: AppColorsLight.border,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColorsLight.panelSoft,
        border: AppColorsLight.border,
        focus: AppColorsLight.stormyTealBright,
        hint: AppColorsLight.textMuted,
      ),
      dialogBackgroundColor: AppColorsLight.panel,
      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsLight.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColorsLight.border),
        ),
        elevation: 8,
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
