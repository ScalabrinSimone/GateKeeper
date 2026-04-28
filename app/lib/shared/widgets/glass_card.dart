import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Card base dell'app GateKeeper.
///
/// Parametri:
/// - [child]: contenuto interno
/// - [padding]: padding interno (default: EdgeInsets.all(16))
/// - [borderColor]: colore bordo (default: [AppColors.border])
/// - [color]: sfondo override opzionale (utile per card 'neutre' più chiare)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? AppColors.border,
        ),
      ),
      child: child,
    );
  }
}
