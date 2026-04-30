import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Logo GateKeeper usato nel login e nella sidebar.
///
/// In un unico posto così, se cambiamo asset (PNG → SVG) basta modificare
/// qui e il resto dell'app resta invariato.
class GateKeeperLogo extends StatelessWidget {
  const GateKeeperLogo({super.key, this.height = 64, this.compact = false});

  /// Altezza desiderata del logo.
  final double height;

  /// Se `true` usa una versione più compatta (es. sidebar stretta).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/gatekeeper_logo.png',
          height: height,
        ),
        if (!compact) ...[
          const SizedBox(width: 8),
          Text(
            'GateKeeper',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.lavenderBlush,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}
