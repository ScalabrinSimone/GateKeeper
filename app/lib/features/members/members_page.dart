import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';

//Vista membri del nucleo familiare.
class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final users = MockData.users;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.t('members'),
            subtitle: l10n.t('manageFamily'),
            actions: [
              GKButton(
                onPressed: () {},
                label: l10n.t('inviteMember'),
                icon: Icons.person_add_alt_rounded,
                variant: GKButtonVariant.secondary,
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 260,
                ),
                itemCount: users.length + 1,
                itemBuilder: (context, i) {
                  if (i == users.length) {
                    return _InviteCard(label: l10n.t('inviteMember'));
                  }
                  return _MemberCard(user: users[i]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final df = DateFormat.Hm();

    final IconData roleIcon;
    switch (user.role) {
      case UserRole.admin:
        roleIcon = Icons.shield_rounded;
        break;
      case UserRole.adult:
        roleIcon = Icons.person_rounded;
        break;
      case UserRole.child:
        roleIcon = Icons.child_care_rounded;
        break;
    }

    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.stormyTeal, AppColors.charcoalBlue]),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(roleIcon, size: 14, color: user.role == UserRole.admin ? AppColors.orangeGold : AppColors.stormyTeal),
                        const SizedBox(width: 6),
                        Text(
                          l10n.t(_roleKey(user.role)).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
          const Spacer(),
          _row(
            theme,
            label: l10n.t('currentStatus'),
            value: user.isInside ? l10n.t('inside') : l10n.t('outside'),
            valueColor: user.isInside ? AppColors.success : AppColors.orangeGold,
            asPill: true,
          ),
          const SizedBox(height: 12),
          _row(
            theme,
            label: l10n.t('lastSeen'),
            value: user.lastSeenAt != null ? df.format(user.lastSeenAt!) : '—',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: GKButton(onPressed: () {}, icon: Icons.mail_outline_rounded, label: l10n.t('logShort'), variant: GKButtonVariant.ghost, dense: true, expanded: true)),
              const SizedBox(width: 8),
              Expanded(child: GKButton(onPressed: () {}, icon: Icons.shield_outlined, label: l10n.t('permissionsShort'), variant: GKButtonVariant.ghost, dense: true, expanded: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, {required String label, required String value, Color? valueColor, bool asPill = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        if (asPill)
          StatusPill(label: value, color: valueColor ?? AppColors.stormyTeal, dense: true)
        else
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
      ],
    );
  }

  String _roleKey(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.adult:
        return 'adult';
      case UserRole.child:
        return 'child';
    }
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(22),
      borderColor: AppColors.stormyTeal.withValues(alpha: 0.2),
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.stormyTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.person_add_alt_rounded, size: 32, color: AppColors.stormyTeal),
          ),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
