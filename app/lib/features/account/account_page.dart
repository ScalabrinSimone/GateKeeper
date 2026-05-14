import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';

//Pagina profilo / account utente.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.auth});

  final AuthController auth;

  Future<void> _logout(BuildContext context) async {
    final l10n = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('logout')),
        content: Text(l10n.t('logoutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.t('logout')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await auth.logout();
    if (context.mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final user = auth.user;
    final displayName = user?.username ?? 'Member';
    final role = user?.role ?? 'adult';
    final email = user?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.t('account'), subtitle: role.toUpperCase()),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final avatar = _AvatarBlock(
                name: displayName,
                role: role.toUpperCase(),
                logoutLabel: l10n.t('logout'),
                onLogout: () => _logout(context),
              );
              final info = Column(
                children: [
                  _ProfileInfo(),
                  const SizedBox(height: 16),
                  _SessionsCard(),
                ],
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: avatar),
                    const SizedBox(width: 24),
                    Expanded(child: info),
                  ],
                );
              }
              return Column(children: [avatar, const SizedBox(height: 20), info]);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'GateKeeper © 2026 • Progetto IoT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.name,
    required this.role,
    required this.logoutLabel,
    required this.onLogout,
  });
  final String name;
  final String role;
  final String logoutLabel;
  final VoidCallback onLogout;

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.stormyTeal, AppColors.charcoalBlue]),
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.stormyTeal.withValues(alpha: 0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              ),
            ),
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orangeGold,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.inkBlack),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text(
          role.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GKButton(
            onPressed: onLogout,
            icon: Icons.logout_rounded,
            label: logoutLabel,
            variant: GKButtonVariant.danger,
            expanded: true,
          ),
        ),
      ],
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('profileInfo').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final two = c.maxWidth >= 480;
              final children = [
                _field(theme, icon: Icons.mail_outline_rounded, label: l10n.t('email'), value: 'marco.rossi@example.it'),
                _field(theme, icon: Icons.phone_rounded, label: l10n.t('phone'), value: '+39 333 4567890'),
                _field(theme, icon: Icons.calendar_today_rounded, label: l10n.t('joined'), value: '12 Gen 2024'),
                _field(theme, icon: Icons.lock_rounded, label: l10n.t('securitySettings'), value: l10n.t('mfaActive')),
              ];
              if (!two) return Column(children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w)).toList());
              return Wrap(
                spacing: 24,
                runSpacing: 18,
                children: [for (final c in children) SizedBox(width: (c is _Field ? 240 : 240).toDouble(), child: c)],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(ThemeData theme, {required IconData icon, required String label, required String value}) {
    return _Field(icon: icon, label: label, value: value);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SessionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      background: AppColors.stormyTeal.withValues(alpha: 0.05),
      borderColor: AppColors.stormyTeal.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('activeSessions').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.stormyTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.devices_rounded, color: AppColors.stormyTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Hub Raspberry Pi', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        'Milano • ${l10n.t('onlineNow')}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                GKButton(onPressed: () {}, label: l10n.t('close'), variant: GKButtonVariant.ghost, dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
