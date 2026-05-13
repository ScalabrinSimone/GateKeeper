import 'package:flutter/material.dart';

//Palette ufficiale GateKeeper e colori derivati per tema chiaro/scuro.
class AppColors {
  AppColors._();

  //Palette principale.
  static const Color inkBlack = Color(0xFF0D1117);
  static const Color charcoalBlue = Color(0xFF41474E);
  static const Color stormyTeal = Color(0xFF00767A);
  static const Color orangeGold = Color(0xFFFFA400);
  static const Color lavenderBlush = Color(0xFFF0E2E7);

  //Alias retro-compatibilità.
  static const Color orange = orangeGold;

  //Stack tema scuro.
  static const Color darkBg = inkBlack;
  static const Color darkCard = Color(0xFF161B22);
  static const Color darkBorder = charcoalBlue;
  static const Color darkText = lavenderBlush;

  //Stack tema chiaro.
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE9ECEF);
  static const Color lightText = Color(0xFF1A1D23);

  //Stati semantici condivisi.
  static const Color success = Color(0xFF2EB872);
  static const Color warning = orangeGold;
  static const Color danger = Color(0xFFE5484D);
  static const Color info = stormyTeal;
}
