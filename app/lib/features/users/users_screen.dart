import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../core/models/models.dart'; // GkUser, UserRole, kFakeUsersJson
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import 'dialogs/invite_dialog.dart';
import 'widgets/user_role_column.dart';

// ---------------------------------------------------------------------------
// Dati stub — derivati dal modello core GkUser
// ---------------------------------------------------------------------------

// Usiamo kFakeUsersJson (definita in gk_user.dart) per costruire la lista
// di utenti fake da mostrare durante lo sviluppo UI.
//
// TODO: rimpiazzare con GET /api/users dal backend FastAPI.
final _stubUsers = kFakeUsersJson.map(GkUser.fromJson).toList();

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata gestione utenti e ruoli.
///
/// Desktop: 3 colonne affiancate (Administrators | Managers | Children).
/// Mobile: colonne in scroll verticale.
///
/// TODO: sostituire _stubUsers con dati reali dal backend.
/// TODO: ⋮ menu utente → dialog modifica ruolo / rimuovi utente.
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  /// Filtra gli utenti stub per ruolo.
  ///
  /// - [role]: il [UserRole] da filtrare (admin / adult / child)
  List<GkUser> _byRole(UserRole role) =>
      _stubUsers.where((u) => u.role == role).toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'User Management',
                trailing: _InviteButton(isMobile: isMobile),
              ),
              Expanded(
                child: isMobile
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          UserRoleColumn(
                            roleTitle: 'Administrators',
                            roleDescription:
                                'Full access to all system settings, alerts, and object tracking.',
                            users: _byRole(UserRole.admin),
                          ),
                          const SizedBox(height: 20),
                          UserRoleColumn(
                            roleTitle: 'Managers',
                            roleDescription:
                                'Can view tracking, dismiss alerts, and edit object tags.',
                            users: _byRole(UserRole.adult),
                          ),
                          const SizedBox(height: 20),
                          UserRoleColumn(
                            roleTitle: 'Children & Guests',
                            roleDescription:
                                'Tracked via BLE. Cannot change settings or view sensitive alerts.',
                            users: _byRole(UserRole.child),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: UserRoleColumn(
                                roleTitle: 'Administrators',
                                roleDescription:
                                    'Full access to all system settings, alerts, and object tracking.',
                                users: _byRole(UserRole.admin),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: UserRoleColumn(
                                roleTitle: 'Managers',
                                roleDescription:
                                    'Can view tracking, dismiss alerts, and edit object tags.',
                                users: _byRole(UserRole.adult),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: UserRoleColumn(
                                roleTitle: 'Children & Guests',
                                roleDescription:
                                    'Tracked via BLE. Cannot change settings or view sensitive alerts.',
                                users: _byRole(UserRole.child),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bottone Invite Member
// ---------------------------------------------------------------------------

class _InviteButton extends StatelessWidget {
  const _InviteButton({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => InviteDialog.show(context),
      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
      label: isMobile ? const SizedBox.shrink() : const Text('Invite Member'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.stormyTeal,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 18,
          vertical: 10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    );
  }
}
