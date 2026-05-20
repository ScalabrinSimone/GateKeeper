import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

//Card riusabile, ispirata allo stile "bento" del mockup.
class GKCard extends StatelessWidget {
  const GKCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.borderColor,
    this.background,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? background;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(borderRadius);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? theme.cardColor,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? theme.dividerColor),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppColors.stormyTeal.withValues(alpha: 0.07),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : const [],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
