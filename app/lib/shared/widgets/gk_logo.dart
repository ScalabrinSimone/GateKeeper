import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

//Logo testuale GateKeeper. Niente banner ridondante: solo il monogramma "GK".
class GKLogo extends StatelessWidget {
  const GKLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.orangeGold : AppColors.stormyTeal;
    final fg = isDark ? AppColors.inkBlack : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Text(
        'GK',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.36,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
