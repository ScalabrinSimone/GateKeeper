import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/gk_badge.dart';
import '../../shared/widgets/gk_empty_state.dart';
import '../../shared/widgets/gk_search_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/user_role_badge.dart';
import 'widgets/user_tile.dart';

// ---------------------------------------------------------------------------
// Modello dati locale (stub finché non c'è backend)
// ---------------------------------------------------------------------------

/// Ruoli disponibili nell'app GateKeeper.
enum UserRole { admin, adult, child }

/// Rappresenta un membro della casa.
///
/// Parametri:
/// - [id]: identificatore univoco
/// - [name]: nome visualizzato
/// - [email]: email/username
/// - [role]: ruolo (admin / adult / child)
/// - [isOnline]: true se BLE lo rileva in casa
class HouseUser {
  const HouseUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isOnline;
}

// ---------------------------------------------------------------------------
// Dati stub
// ---------------------------------------------------------------------------

/// TODO: rimpiazzare con chiamata GET /api/users dal backend.
const _stubUsers = [
  HouseUser(
    id: '1',
    name: 'Alice',
    email: 'alice@home.local',
    role: UserRole.admin,
    isOnline: true,
  ),
  HouseUser(
    id: '2',
    name: 'Bob',
    email: 'bob@home.local',
    role: UserRole.adult,
    isOnline: true,
  ),
  HouseUser(
    id: '3',
    name: 'Charlie',
    email: 'charlie@home.local',
    role: UserRole.child,
    isOnline: false,
  ),
  HouseUser(
    id: '4',
    name: 'Dave',
    email: 'dave@home.local',
    role: UserRole.child,
    isOnline: true,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata gestione utenti e ruoli.
///
/// Responsabilità:
/// - visualizza lista membri della casa con ruolo e presenza BLE;
/// - permette ricerca per nome;
/// - l'admin può invitare nuovi utenti (dialog nel Blocco 2B).
///
/// TODO (Blocco 2B): collegare bottone "Invite" al dialog.
/// TODO: chiamata GET /api/users per popolare _users.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Lista filtrata in base alla ricerca
  List<HouseUser> _filtered = _stubUsers;

  void _onSearch(String query) {
    setState(() {
      _filtered = _stubUsers
          .where((u) =>
              u.name.toLowerCase().contains(query.toLowerCase()) ||
              u.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

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
                title: 'Users & Roles',
                trailing: _InviteButton(isMobile: isMobile),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    0,
                    isMobile ? 16 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra di ricerca
                      GkSearchBar(
                        hint: 'Search members…',
                        onChanged: _onSearch,
                      ),
                      const SizedBox(height: 16),

                      // Contatori ruolo in alto (solo desktop)
                      if (!isMobile) _RoleSummaryRow(users: _stubUsers),
                      if (!isMobile) const SizedBox(height: 20),

                      // Lista utenti
                      if (_filtered.isEmpty)
                        const GkEmptyState(
                          icon: Icons.group_off_outlined,
                          title: 'No members found',
                          subtitle:
                              'Try a different search or invite a new member.',
                        )
                      else
                        GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (int i = 0; i < _filtered.length; i++) ...
                                [
                                  UserTile(user: _filtered[i]),
                                  // Divider tra voci ma non dopo l'ultima
                                  if (i < _filtered.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                      indent: 60,
                                    ),
                                ],
                            ],
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
// Widget locali
// ---------------------------------------------------------------------------

/// Bottone "Invite Member" — nel Blocco 2B aprirà il dialog.
class _InviteButton extends StatelessWidget {
  const _InviteButton({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO (Blocco 2B): showInviteDialog(context)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite dialog — coming in Block 2B')),
        );
      },
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

/// Riga di riepilogo con numero di Admin / Adult / Child.
class _RoleSummaryRow extends StatelessWidget {
  const _RoleSummaryRow({required this.users});

  final List<HouseUser> users;

  int _count(UserRole r) => users.where((u) => u.role == r).length;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleChip(
          label: 'Admin',
          count: _count(UserRole.admin),
          color: AppColors.orange,
        ),
        const SizedBox(width: 10),
        _RoleChip(
          label: 'Adult',
          count: _count(UserRole.adult),
          color: AppColors.stormyTealBright,
        ),
        const SizedBox(width: 10),
        _RoleChip(
          label: 'Child',
          count: _count(UserRole.child),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label),
        ],
      ),
    );
  }
}
