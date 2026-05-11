import 'package:flutter/material.dart';

import '../../../core/models/models.dart'; // UserRole — definita in gk_user.dart
import '../../../theme/app_colors.dart';

// NOTA: prima importava '../users_screen.dart' per UserRole.
// UserRole è ora nel core model → import aggiornato.

/// Badge colorato con il ruolo dell'utente.
///
/// Usato nelle card utente e in altri contesti dove si vuole
/// mostrare il ruolo in formato compatto (pill colorata).
///
/// Parametri:
/// - [role]: valore enum [UserRole] (admin / adult / child)
///
/// Esempio:
/// ```dart
/// UserRoleBadge(role: user.role)
/// ```
class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    // Associa ogni ruolo a una etichetta e un colore differente
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
