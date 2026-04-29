import 'package:flutter/services.dart';

/// Utility semplice per dare feedback aptico.
///
/// Su desktop/web spesso non farà nulla, ed è normale.
/// Su mobile invece migliora la sensazione di "app moderna".
///
/// Utilizzo:
/// ```dart
/// AppHaptics.light();     // tap su chip/filtro
/// AppHaptics.selection(); // cambio voce di navigazione
/// AppHaptics.heavy();     // azione distruttiva
/// AppHaptics.success();   // conferma completamento
/// ```
///
/// NOTE: questa classe è un wrapper leggero su [HapticFeedback].
/// Per pattern di vibrazione avanzati usa [HapticService] in
/// core/services/haptic_service.dart.
abstract final class AppHaptics {
  /// Vibrazione leggera — tap, selezione chip/filtro.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Vibrazione media — conferma, toggle switch.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Vibrazione pesante — azione irreversibile, eliminazione.
  /// Alias di HapticService.heavy() per uniformità API.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Click di selezione — cambio voce navigazione.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Notifica di successo.
  /// Alias di HapticService.success() per uniformità API.
  static Future<void> success() => HapticFeedback.selectionClick();
}
