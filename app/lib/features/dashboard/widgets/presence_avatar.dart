import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Avatar circolare con pallino di presenza (mobile).
///
/// Parametri:
/// - [name]: nome da visualizzare sotto l'avatar
/// - [isOnline]: true = pallino verde, false = pallino grigio
class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar({
    super.key,
    required this.name,
    this.isOnline = true,
  });

  final String name;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.panelSoft,
              child: const Icon(Icons.person,
                  color: AppColors.textSecondary, size: 28),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.inkBlack, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
