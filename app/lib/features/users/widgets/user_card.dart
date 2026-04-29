import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../users_screen.dart';

/// Card di un singolo utente, fedele al design Figma.
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────┐
/// │  [avatar]  Nome (You?)     ⋮            │
/// │            email                        │
/// │  ──────────────────────────────────     │
/// │  PERMISSIONS                            │
/// │  ✓ Full Control                         │
/// │  ✓ Manage Users                         │
/// └─────────────────────────────────────────┘
/// ```
///
/// Parametri:
/// - [user]: dato di tipo [HouseUser]
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
                    // Pallino BLE in basso a destra sull'avatar
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
                          // Bordo per staccare il pallino dallo sfondo
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

                // Nome + email (o 'No Account')
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome con badge '(You)' se è l'utente corrente
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.isCurrentUser
                                  ? '${user.name} (You)'
                                  : user.name,
                              style: AppTextStyles.cardTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.hasAccount
                            ? user.email
                            : 'No Account',
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Menu ⋮ (tre puntini)
                IconButton(
                  onPressed: () {
                    // TODO (Blocco 2B): PopupMenu con Modifica ruolo / Rimuovi
                    _showUserMenu(context);
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  // Riduce il padding attorno all'icona
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Divider tra header e permessi
          const Divider(height: 1, color: AppColors.border),

          // Sezione permessi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label 'PERMISSIONS'
                const Text('PERMISSIONS', style: AppTextStyles.label),
                const SizedBox(height: 8),

                // Lista permessi con checkmark
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

  /// Mostra un PopupMenuButton posizionato vicino al bottone ⋮.
  /// TODO (Blocco 2B): sostituire con dialog modale con blur.
  void _showUserMenu(BuildContext context) {
    final RenderBox button =
        context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()
            as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Change Role')),
        PopupMenuItem(value: 'remove', child: Text('Remove Member')),
      ],
    );
  }
}
