import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            color: AppColors.panelSoft,
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_none, size: 18, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Alerts (2)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.panelSoft,
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.orange,
                child: Icon(Icons.person, size: 16, color: AppColors.inkBlack),
              ),
              SizedBox(width: 8),
              Text(
                'Alice',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}