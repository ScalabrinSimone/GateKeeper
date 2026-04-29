import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Chip/badge colorato generico riusabile in tutta l'app.
///
/// Parametri:
/// - [label]: testo visualizzato
/// - [color]: colore di sfondo (default: [AppColors.stormyTeal])
/// - [textColor]: colore testo (default: bianco)
class GkBadge extends StatelessWidget {
  const GkBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.stormyTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // 20 % di opacità sul colore scelto
        color: bg.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? bg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
