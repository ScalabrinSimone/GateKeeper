import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Barra azioni in alto a destra: notifiche + profilo utente.
///
/// Appare sempre allineata a destra nel PageHeader.
/// TODO: collegare al provider notifiche e al modello utente corrente.
class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Badge Alerts ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            color: AppColors.panelSoft,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none,
                  size: 18, color: AppColors.textPrimary),
              SizedBox(width: 6),
              Text(
                'Alerts (2)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // --- Profilo utente ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.panelSoft,
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.orange,
                child:
                    Icon(Icons.person, size: 14, color: AppColors.inkBlack),
              ),
              SizedBox(width: 6),
              Text(
                'Alice',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}
