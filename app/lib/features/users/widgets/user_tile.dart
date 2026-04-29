import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../users_screen.dart';
import 'user_role_badge.dart';

/// Riga utente nella lista di Users & Roles.
///
/// Mostra:
/// - avatar con iniziale e colore legato al ruolo;
/// - nome, email;
/// - badge ruolo;
/// - pallino presenza BLE (verde = in casa, grigio = fuori).
///
/// Parametri:
/// - [user]: dato di tipo [HouseUser]
class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user});

  final HouseUser user;

  // Colore avatar per ruolo
  Color _avatarColor() => switch (user.role) {
        UserRole.admin => AppColors.orange,
        UserRole.adult => AppColors.stormyTeal,
        UserRole.child => AppColors.panelSoft,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Avatar con iniziale
          CircleAvatar(
            radius: 22,
            backgroundColor: _avatarColor().withValues(alpha: 0.25),
            child: Text(
              user.name[0].toUpperCase(),
              style: TextStyle(
                color: _avatarColor(),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nome + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.body),
              ],
            ),
          ),

          // Badge ruolo
          UserRoleBadge(role: user.role),
          const SizedBox(width: 12),

          // Pallino presenza BLE
          Tooltip(
            message: user.isOnline ? 'At home (BLE)' : 'Away',
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.isOnline
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
