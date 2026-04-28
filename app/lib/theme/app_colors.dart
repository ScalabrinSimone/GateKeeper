import 'package:flutter/material.dart';

/// Palette GateKeeper derivata dal mockup.
///
/// NOTE:
/// - i nomi sono semantici, non "teal1 / teal2";
/// - così puoi cambiare il colore reale senza rompere il significato.
abstract final class AppColors {
  static const Color inkBlack = Color(0xFF0D1117);
  static const Color deepNavy = Color(0xFF121826);
  static const Color panel = Color(0xFF171D2B);
  static const Color panelSoft = Color(0xFF1B2232);
  static const Color border = Color(0xFF31394A);

  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFFA0A9BC);
  static const Color textMuted = Color(0xFF6E7687);

  static const Color stormyTeal = Color(0xFF00767A);
  static const Color stormyTealBright = Color(0xFF10B7BE);

  static const Color orange = Color(0xFFFFA400);
  static const Color warning = Color(0xFFFFB020);

  static const Color success = Color(0xFF16C79A);
  static const Color live = Color(0xFF0ED2C3);

  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
}