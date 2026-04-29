import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/user_role_column.dart';

// ---------------------------------------------------------------------------
// Modello dati
// ---------------------------------------------------------------------------

/// Ruoli disponibili nel sistema GateKeeper.
///
/// - [admin]: accesso totale a impostazioni, alert e oggetti
/// - [adult]: può vedere tracking, gestire tag e dismissare alert
/// - [child]: tracciato via BLE, nessun accesso a settings o alert sensibili
enum UserRole { admin, adult, child }

/// Singolo permesso mostrato nella card utente.
///
/// Parametri:
/// - [label]: testo del permesso (es. 'Full Control')
class UserPermission {
  const UserPermission(this.label);
  final String label;
}

/// Membro della casa registrato nel sistema.
///
/// Parametri:
/// - [id]: identificatore univoco
/// - [name]: nome visualizzato (es. 'Alice')
/// - [email]: email/username (es. 'alice@home.local')
/// - [role]: ruolo [UserRole]
/// - [isOnline]: true se il dispositivo BLE è rilevato in casa
/// - [isCurrentUser]: true per l'utente loggato (mostra '(You)')
/// - [hasAccount]: false per bambini/ospiti senza login
/// - [permissions]: lista permessi mostrati nella card
class HouseUser {
  const HouseUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isOnline = false,
    this.isCurrentUser = false,
    this.hasAccount = true,
    this.permissions = const [],
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isOnline;
  final bool isCurrentUser;
  final bool hasAccount;
  final List<UserPermission> permissions;
}

// ---------------------------------------------------------------------------
// Dati stub
// ---------------------------------------------------------------------------

/// TODO: rimpiazzare con GET /api/users dal backend FastAPI.
const _stubUsers = [
  HouseUser(
    id: '1',
    name: 'Alice',
    email: 'alice@home.local',
    role: UserRole.admin,
    isOnline: true,
    isCurrentUser: true,
    permissions: [
      UserPermission('Full Control'),
      UserPermission('Manage Users'),
      UserPermission('Alert Configuration'),
    ],
  ),
  HouseUser(
    id: '2',
    name: 'Bob',
    email: 'bob@home.local',
    role: UserRole.adult,
    isOnline: true,
    permissions: [
      UserPermission('View History'),
      UserPermission('Edit Tags'),
      UserPermission('Dismiss Alerts'),
    ],
  ),
  HouseUser(
    id: '3',
    name: 'Charlie',
    email: '',
    role: UserRole.child,
    isOnline: false,
    hasAccount: false,
    permissions: [
      UserPermission('BLE Tracking Only'),
      UserPermission('View Own History'),
    ],
  ),
  HouseUser(
    id: '4',
    name: 'Dave',
    email: '',
    role: UserRole.child,
    isOnline: true,
    hasAccount: false,
    permissions: [
      UserPermission('BLE Tracking Only'),
      UserPermission('View Own History'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata gestione utenti e ruoli.
///
/// Desktop: 3 colonne affiancate (Administrators | Managers | Children & Guests).
/// Mobile: colonne in scroll verticale.
///
/// Ogni colonna mostra:
/// - titolo ruolo + badge count + descrizione;
/// - card per ogni utente con avatar, nome/email, menu ⋮ e lista permessi.
///
/// TODO (Blocco 2B): ⋮ menu → dialog modifica ruolo / rimuovi utente.
/// TODO (Blocco 2B): bottone Invite Member → dialog invito.
/// TODO: sostituire _stubUsers con stream dal backend.
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  // Filtra gli utenti per ruolo
  List<HouseUser> _byRole(UserRole role) =>
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
                    // Mobile: colonne in scroll verticale
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
                    // Desktop: 3 colonne affiancate con IntrinsicHeight
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
      onPressed: () {
        // TODO (Blocco 2B): showInviteDialog(context)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite dialog — coming in Block 2B'),
          ),
        );
      },
      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
      label: isMobile
          ? const SizedBox.shrink()
          : const Text('Invite Member'),
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
