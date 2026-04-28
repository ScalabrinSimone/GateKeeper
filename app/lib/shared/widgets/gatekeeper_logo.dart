import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class GateKeeperLogo extends StatelessWidget {
  const GateKeeperLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.stormyTeal,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.shield_outlined,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
        SizedBox(width: 12),
        Text(
          'GateKeeper',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}