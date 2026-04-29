import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../users_screen.dart';

/// Badge colorato con il ruolo dell'utente.
///
/// I colori seguono la gerarchia:
/// - Admin → arancione (valore più alto)
/// - Adult → teal
/// - Child → grigio
///
/// Parametri:
/// - [role]: valore enum [UserRole]
class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.admin => ('Admin', AppColors.orange),
      UserRole.adult => ('Adult', AppColors.stormyTealBright),
      UserRole.child => ('Child', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
