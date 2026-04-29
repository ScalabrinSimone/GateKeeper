import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Palette dark (tema principale)
// ---------------------------------------------------------------------------

/// Colori del tema DARK.
///
/// Questa classe rimane il punto di verità per il dark theme.
/// I widget che usano questi colori direttamente sono corretti —
/// nel dark theme questi sono sempre validi.
///
/// Per i widget che devono adattarsi al tema chiaro, usare
/// [AppColorsLight] oppure leggere dal [Theme.of(context).colorScheme].
///
/// NOTE: i nomi sono semantici, non tecnici (es. "panel" non "gray1").
/// Se cambi un valore esadecimale, il significato rimane invariato.
abstract final class AppColors {
  // ── Sfondi e superfici (dark) ────────────────────────────────────────────
  static const Color inkBlack  = Color(0xFF0D1117); // sfondo app più scuro
  static const Color deepNavy  = Color(0xFF121826); // sfondo secondario
  static const Color panel     = Color(0xFF171D2B); // pannelli/card
  static const Color panelSoft = Color(0xFF1B2232); // card interne / input
  static const Color border    = Color(0xFF31394A); // bordi sottili

  // ── Testo (dark) ─────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFA0A9BC);
  static const Color textMuted     = Color(0xFF6E7687);

  // ── Accent primario (teal) — invariante tra temi ─────────────────────────
  static const Color stormyTeal       = Color(0xFF00767A);
  static const Color stormyTealBright = Color(0xFF10B7BE);

  // ── Stato — invarianti tra temi ──────────────────────────────────────────
  static const Color success = Color(0xFF16C79A);
  static const Color live    = Color(0xFF0ED2C3);
  static const Color warning = Color(0xFFFFB020);
  static const Color orange  = Color(0xFFFFA400);

  /// Colore per errori di validazione e messaggi di errore inline.
  ///
  /// Esempio:
  /// ```dart
  /// Text('Campo obbligatorio', style: TextStyle(color: AppColors.error))
  /// ```
  static const Color error = Color(0xFFFF5C5C);

  /// Alias semantico di [error] per azioni distruttive (es. "Delete", "Remove").
  /// Tenere separato permette di differenziare errori passivi da azioni attive.
  static const Color danger = Color(0xFFFF5C5C);

  // ── Utilità ──────────────────────────────────────────────────────────────
  static const Color white       = Colors.white;
  static const Color transparent = Colors.transparent;
}

// ---------------------------------------------------------------------------
// Palette light (tema chiaro)
// ---------------------------------------------------------------------------

/// Colori del tema LIGHT.
///
/// Segue la stessa palette del progetto (teal, orange) ma con superfici
/// chiare e testo scuro. I colori semantici (success, warning, error)
/// rimangono identici perché funzionano bene su entrambi i fondali.
///
/// Utilizzo nei widget:
/// ```dart
/// // Scegli in base al tema attivo:
/// final colors = Theme.of(context).brightness == Brightness.dark
///     ? AppColors.self    // usa AppColors direttamente
///     : AppColorsLight.self;
/// ```
///
/// Oppure usa il helper [AppThemeColors.of(context)] definito in app_theme.dart.
abstract final class AppColorsLight {
  // ── Sfondi e superfici (light) ────────────────────────────────────────────
  /// Sfondo principale — bianco leggermente caldo per non essere abbagliante.
  static const Color inkBlack  = Color(0xFFF0E2E7); // Lavender Blush dal mockup
  static const Color deepNavy  = Color(0xFFE8D8DE);
  static const Color panel     = Color(0xFFFFFFFF); // card bianche
  static const Color panelSoft = Color(0xFFF8F2F4); // input / card interne
  static const Color border    = Color(0xFFDDCDD4); // bordi tenui

  // ── Testo (light) ────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D1117); // Ink Black dal mockup
  static const Color textSecondary = Color(0xFF41474E); // Charcoal Blue
  static const Color textMuted     = Color(0xFF7A8090);

  // ── Accent primario — identico al dark (brand color) ─────────────────────
  static const Color stormyTeal       = Color(0xFF00767A);
  static const Color stormyTealBright = Color(0xFF0A9DA4);

  // ── Stato — identici (leggibili su entrambi i fondali) ───────────────────
  static const Color success = Color(0xFF16C79A);
  static const Color live    = Color(0xFF0ED2C3);
  static const Color warning = Color(0xFFFFB020);
  static const Color orange  = Color(0xFFFFA400);
  static const Color error   = Color(0xFFE53935);
  static const Color danger  = Color(0xFFE53935);

  // ── Utilità ──────────────────────────────────────────────────────────────
  static const Color white       = Colors.white;
  static const Color transparent = Colors.transparent;
}

// ---------------------------------------------------------------------------
// Helper per leggere i colori corretti in base al tema attivo
// ---------------------------------------------------------------------------

/// Restituisce i valori di colore giusti in base al [Brightness] del tema.
///
/// Questo è il modo consigliato per usare i colori nei widget che devono
/// supportare entrambi i temi senza switch ripetitivi ovunque.
///
/// Esempio:
/// ```dart
/// final c = AppThemeColors.of(context);
/// Container(color: c.panel, child: Text('Ciao', style: TextStyle(color: c.textPrimary)))
/// ```
class AppThemeColors {
  const AppThemeColors._({required this.brightness});

  /// Crea un'istanza leggendo il brightness dal [BuildContext].
  factory AppThemeColors.of(BuildContext context) {
    return AppThemeColors._(
      brightness: Theme.of(context).brightness,
    );
  }

  final Brightness brightness;
  bool get _isDark => brightness == Brightness.dark;

  // ── Superfici ─────────────────────────────────────────────────────────────
  Color get inkBlack  => _isDark ? AppColors.inkBlack  : AppColorsLight.inkBlack;
  Color get deepNavy  => _isDark ? AppColors.deepNavy  : AppColorsLight.deepNavy;
  Color get panel     => _isDark ? AppColors.panel     : AppColorsLight.panel;
  Color get panelSoft => _isDark ? AppColors.panelSoft : AppColorsLight.panelSoft;
  Color get border    => _isDark ? AppColors.border    : AppColorsLight.border;

  // ── Testo ─────────────────────────────────────────────────────────────────
  Color get textPrimary   => _isDark ? AppColors.textPrimary   : AppColorsLight.textPrimary;
  Color get textSecondary => _isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted     => _isDark ? AppColors.textMuted     : AppColorsLight.textMuted;

  // ── Accent (invarianti) ───────────────────────────────────────────────────
  Color get stormyTeal       => AppColors.stormyTeal;
  Color get stormyTealBright => _isDark ? AppColors.stormyTealBright : AppColorsLight.stormyTealBright;

  // ── Stato (invarianti) ────────────────────────────────────────────────────
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get orange  => AppColors.orange;
  Color get error   => _isDark ? AppColors.error : AppColorsLight.error;
  Color get danger  => _isDark ? AppColors.danger : AppColorsLight.danger;
}
