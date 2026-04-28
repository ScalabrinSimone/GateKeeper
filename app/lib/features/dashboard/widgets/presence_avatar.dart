import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar({
    super.key,
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.panelSoft,
              child: Icon(Icons.person, color: AppColors.textPrimary),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.live,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.inkBlack, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}