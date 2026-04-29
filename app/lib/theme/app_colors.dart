import 'package:flutter/material.dart';

/// Palette GateKeeper derivata dal mockup Figma.
///
/// NOTE:
/// - i nomi sono semantici, non "teal1 / teal2";
/// - così puoi cambiare il valore esadecimale senza rompere il significato;
/// - aggiungi qui ogni nuovo colore prima di usarlo nel codice,
///   così tutti i file importano da un unico punto di verità.
abstract final class AppColors {
  // ── Sfondi e superfici ──────────────────────────────────────────────────
  static const Color inkBlack  = Color(0xFF0D1117); // sfondo app più scuro
  static const Color deepNavy  = Color(0xFF121826); // sfondo secondario
  static const Color panel     = Color(0xFF171D2B); // pannelli/card
  static const Color panelSoft = Color(0xFF1B2232); // card interne / input
  static const Color border    = Color(0xFF31394A); // bordi sottili

  // ── Testo ───────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF4F7FB); // titoli / label
  static const Color textSecondary = Color(0xFFA0A9BC); // testo secondario
  static const Color textMuted     = Color(0xFF6E7687); // placeholder / hint

  // ── Accent primario (teal) ───────────────────────────────────────────────
  static const Color stormyTeal       = Color(0xFF00767A); // bottoni CTA
  static const Color stormyTealBright = Color(0xFF10B7BE); // icone / highlight

  // ── Stato ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16C79A); // confermato / online
  static const Color live    = Color(0xFF0ED2C3); // badge "live"
  static const Color warning = Color(0xFFFFB020); // avvisi non critici
  static const Color orange  = Color(0xFFFFA400); // stato "away" oggetti

  /// Colore per errori di validazione, messaggi di errore inline
  /// e qualsiasi testo che comunica un problema all'utente.
  ///
  /// Esempio d'uso:
  /// ```dart
  /// Text('Campo obbligatorio', style: TextStyle(color: AppColors.error))
  /// ```
  ///
  /// TODO: se il design Figma prevede una tonalità diversa per l'errore,
  /// aggiorna questo valore mantenendo il nome.
  static const Color error = Color(0xFFFF5C5C);

  /// Alias semantico di [error] usato per azioni distruttive
  /// (es. "Remove Member", "Delete object").
  ///
  /// Tenere separato da [error] permette di differenziare
  /// errori passivi (validazione) da azioni attive (eliminazione).
  static const Color danger = Color(0xFFFF5C5C);

  // ── Utilità ─────────────────────────────────────────────────────────────
  static const Color white       = Colors.white;
  static const Color transparent = Colors.transparent;
}
