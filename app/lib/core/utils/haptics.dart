import 'package:flutter/services.dart';

/// Utility semplice per dare feedback aptico.
///
/// Su desktop/web spesso non farà nulla, ed è normale.
/// Su mobile invece migliora la sensazione di "app moderna".
abstract final class AppHaptics {
  static Future<void> light() => HapticFeedback.lightImpact();

  static Future<void> medium() => HapticFeedback.mediumImpact();

  static Future<void> selection() => HapticFeedback.selectionClick();
}