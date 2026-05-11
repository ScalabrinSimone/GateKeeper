import 'package:flutter/services.dart';

/// Servizio centralizzato per il feedback aptico.
///
/// Centralizzare qui le chiamate evita di sparpagliare
/// [HapticFeedback] in tutta la UI. Se domani vuoi usare
/// il package `vibration` per pattern custom, cambi solo qui.
///
/// Utilizzo:
/// ```dart
/// HapticService.light();   // tap su bottone secondario
/// HapticService.medium();  // conferma azione
/// HapticService.heavy();   // azione distruttiva (es. rimozione utente)
/// HapticService.success(); // sequenza vibrazione breve-pausa-breve
/// ```
abstract final class HapticService {
  /// Vibrazione leggera — tap, selezione chip/filtro.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Vibrazione media — conferma, toggle switch.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Vibrazione pesante — azione irreversibile, eliminazione.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Notifica di successo (pattern predefinito del sistema).
  static Future<void> success() => HapticFeedback.selectionClick();

  /// Notifica di errore — usato su form validation failure.
  /// Usa selectionClick come fallback; sostituisci con
  /// `Vibration.vibrate(pattern: [0,80,60,80])` se usi il package vibration.
  static Future<void> error() => HapticFeedback.vibrate();
}
