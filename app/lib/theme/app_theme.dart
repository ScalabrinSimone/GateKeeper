import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Temi globali dell'app GateKeeper.
///
/// Contiene due [ThemeData] completi:
/// - [darkTheme]: tema scuro (default, mockup principale)
/// - [lightTheme]: tema chiaro (attivabile dal toggle in TopActionBar o Settings)
///
/// Entrambi usano Material 3 con la stessa palette brand:
/// - Primary: Stormy Teal (#00767A)
/// - Secondary: Orange (#FFA400)
///
/// # Note importanti
/// I widget che leggono `Theme.of(context).colorScheme.*` si aggiornano
/// automaticamente al cambio tema. I widget con colori [AppColors] hardcoded
/// (es. [AppShell], [DesktopSidebar]) sono stati aggiornati separatamente
/// per usare `Theme.of(context)` — questo era il bug del dark/light mode.
class AppTheme {
  AppTheme._();

  // ── Dark Theme (mockup principale) ─────────────────────────────────────

  /// Tema scuro di riferimento: sfondo Ink Black, pannelli Charcoal,
  /// accenti Stormy Teal / Orange, testi chiari.
  ///
  /// Questo è il tema "principale" del progetto, che riproduce fedelmente
  /// il mockup Figma. Non modificare senza aggiornare anche il mockup.
  static ThemeData get darkTheme {
    // ColorScheme.fromSeed genera automaticamente le varianti Material 3
    // (surface, surfaceContainer, onSurface, ecc.) partendo dal seed teal.
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.stormyTeal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.stormyTeal,
      secondary: AppColors.orange,
      surface: AppColors.panel,           // card background principale
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,

      // Lo scaffoldBackgroundColor viene sovrascritto da AppShell
      // con il gradiente, ma lo definiamo comunque per widget standalone.
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
        focus: AppColors.stormyTeal,
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

  // ── Light Theme ─────────────────────────────────────────────────────────

  /// Tema chiaro: sfondo bianco/grigio neutro, pannelli chiari, testo Ink Black.
  ///
  /// Usa `ColorScheme.fromSeed` con brightness light per generare le
  /// superfici Material 3 automaticamente. Il `scaffoldBackgroundColor`
  /// usa `cs.surface` (bianco pulito) invece di `AppColors.lavenderBlush`
  /// che risultava troppo rosato e non coerente con un'interfaccia professionale.
  ///
  /// # Fix rispetto alla versione precedente
  /// - PRIMA: `scaffoldBackgroundColor: AppColors.lavenderBlush` → sfondo rosato
  /// - ORA:   `scaffoldBackgroundColor: cs.surface` → bianco neutro
  /// - PRIMA: `background: AppColors.lavenderBlush` in colorScheme → deprecato in M3
  /// - ORA:   rimosso, `surface` gestisce entrambi i casi in Material 3
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.stormyTeal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.stormyTeal,
      secondary: AppColors.orange,
      // surface e surfaceContainer vengono generati automaticamente da fromSeed
      // (bianchi/quasi bianchi con leggera tinta teal) — non sovrascriviamo
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,

      // cs.surface è il bianco "brand-tinted" generato da fromSeed — coerente
      // con le card e i contenitori che usano surfaceContainerLow/High
      scaffoldBackgroundColor: cs.surface,
      fontFamily: AppTextStyles.fontFamily,

      // cardColor leggermente off-white per distinguere le card dallo sfondo
      cardColor: cs.surfaceContainerLow,
      dividerColor: cs.outlineVariant,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme: _inputTheme(
        fill: cs.surfaceContainerLow,
        border: cs.outline.withValues(alpha: 0.35),
        focus: AppColors.stormyTeal,
        hint: cs.onSurfaceVariant,
      ),

      dialogBackgroundColor: cs.surface,
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant),
        ),
        elevation: 6,
      ),
    );
  }

  // ── Helper privato ───────────────────────────────────────────────────────

  /// Costruisce un [InputDecorationTheme] consistente per entrambi i temi.
  ///
  /// Parametri:
  /// - [fill]: colore di sfondo del campo di input
  /// - [border]: colore del bordo a riposo
  /// - [focus]: colore del bordo quando il campo ha il focus
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
