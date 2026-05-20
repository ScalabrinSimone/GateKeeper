import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

enum GKButtonVariant { primary, secondary, ghost, outline, danger }

//Bottone unificato GateKeeper con varianti, haptic e animazione scale on press.
class GKButton extends StatefulWidget {
  const GKButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = GKButtonVariant.primary,
    this.dense = false,
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final GKButtonVariant variant;
  final bool dense;
  final bool expanded;

  @override
  State<GKButton> createState() => _GKButtonState();
}

class _GKButtonState extends State<GKButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case GKButtonVariant.primary:
        bg = AppColors.stormyTeal;
        fg = Colors.white;
        border = null;
        break;
      case GKButtonVariant.secondary:
        bg = AppColors.orangeGold;
        fg = AppColors.inkBlack;
        border = null;
        break;
      case GKButtonVariant.ghost:
        bg = Colors.transparent;
        fg = scheme.onSurface;
        border = Border.all(color: scheme.onSurface.withValues(alpha: 0.12));
        break;
      case GKButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.stormyTeal;
        border = Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.35));
        break;
      case GKButtonVariant.danger:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        border = null;
        break;
    }

    final padding = widget.dense
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 22, vertical: 14);
    final radius = BorderRadius.circular(widget.dense ? 14 : 20);

    final enabled = widget.onPressed != null;

    final content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: widget.dense ? 16 : 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: widget.dense ? 11 : 13,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AnimatedScale(
        scale: _pressed && enabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onPressed!();
                    }
                  : null,
              child: Ink(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radius,
                  border: border,
                ),
                child: Padding(padding: padding, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
