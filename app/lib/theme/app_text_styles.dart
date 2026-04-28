import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Stili testuali comuni.
///
/// TODO: quando importerai i font definitivi da Figma,
/// aggiorna `fontFamily` nel tema e qui regola pesi/dimensioni.
abstract final class AppTextStyles {
  static const String fontFamily = 'Inter';

  static const TextStyle pageTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle metric = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}