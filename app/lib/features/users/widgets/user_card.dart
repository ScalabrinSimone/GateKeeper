import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../users_screen.dart';

/// Card di un singolo utente, fedele al design Figma.
///
/// Layout:
/// ```
/// ┌────────────────────────────────────────┐
/// │  [avatar]  Nome (You?)        ⋮        │
/// │            email / No Account          │
/// │  ──────────────────────────────────    │
/// │  PERMISSIONS                           │
/// │  ✓ Full Control                        │
/// │  ✓ Manage Users                        │
/// └────────────────────────────────────────┘
/// ```
///
/// Parametri:
/// - [user]: dato di tipo [HouseUser] con nome, email, ruolo e permessi
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});

  final HouseUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sezione header: avatar + nome/email + menu ⋮
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar con pallino presenza BLE
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppColors.stormyTeal.withValues(alpha: 0.25),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.stormyTealBright,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    // Pallino BLE in basso a destra: verde = online, grigio = offline
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: user.isOnline
                              ? AppColors.success
                              : AppColors.textMuted,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.panelSoft,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Nome + email (o 'No Account' per bambini senza profilo)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isCurrentUser
                            ? '${user.name} (You)'
                            : user.name,
                        style: AppTextStyles.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.hasAccount ? user.email : 'No Account',
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Menu ⋮ ──────────────────────────────────────────────
                // Usiamo PopupMenuButton direttamente (non showMenu manuale)
                // perché si posiziona automaticamente rispetto al widget.
                PopupMenuButton<_UserMenuAction>(
                  // Icona ⋮
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  color: AppColors.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  // Apre il menu in alto a sinistra rispetto al bottone
                  position: PopupMenuPosition.under,
                  onOpened: () => HapticService.light(),
                  onSelected: (action) async {
                    switch (action) {
                      case _UserMenuAction.changeRole:
                        // TODO: aprire ChangeRoleDialog → PATCH /api/users/{id}/role
                        await HapticService.light();
                      case _UserMenuAction.remove:
                        // TODO: aprire dialog di conferma → DELETE /api/users/{id}
                        // Vibrazione pesante: azione distruttiva
                        await HapticService.heavy();
                    }
                  },
                  itemBuilder: (context) => [
                    // ── Voce: Change Role ──
                    const PopupMenuItem(
                      value: _UserMenuAction.changeRole,
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Change Role',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Divider ──
                    const PopupMenuDivider(height: 1),
                    // ── Voce: Remove Member (rossa = azione distruttiva) ──
                    const PopupMenuItem(
                      value: _UserMenuAction.remove,
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_outlined,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Remove Member',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Sezione permessi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PERMISSIONS', style: AppTextStyles.label),
                const SizedBox(height: 8),
                ...user.permissions.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          color: AppColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Azioni disponibili nel menu ⋮ della UserCard.
///
/// Usato come tipo generico di [PopupMenuButton] per avere
/// type-safety invece di stringhe libere.
enum _UserMenuAction {
  /// Apre il dialog per cambiare il ruolo dell'utente
  changeRole,

  /// Apre il dialog di conferma per rimuovere l'utente dalla casa
  remove,
}
