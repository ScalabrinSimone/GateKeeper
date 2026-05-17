import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/api_config.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/dto.dart';
import '../../data/gatekeeper_api.dart';
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
                isAdmin: user?.isAdmin ?? false,
                logoutLabel: l10n.t('logout'),
                onLogout: () => _logout(context),
              );
              final info = Column(
                children: [
                  _ProfileInfo(user: user, email: email),
                  const SizedBox(height: 16),
                  _EmailVerificationCard(auth: auth),
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
    required this.isAdmin,
    required this.logoutLabel,
    required this.onLogout,
  });
  final String name;
  final String role;
  final bool isAdmin;
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
            if (isAdmin)
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
  const _ProfileInfo({required this.user, required this.email});
  final UserDto? user;
  final String email;

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMd().format(d.toLocal());
  }

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
              final children = <Widget>[
                _Field(
                  icon: Icons.mail_outline_rounded,
                  label: l10n.t('profileEmailLabel'),
                  value: email.isNotEmpty ? email : '—',
                ),
                _Field(
                  icon: Icons.shield_outlined,
                  label: l10n.t('profileRoleLabel'),
                  value: (user?.role ?? '—').toUpperCase(),
                ),
                _Field(
                  icon: Icons.calendar_today_rounded,
                  label: l10n.t('profileMemberSince'),
                  value: _fmt(user?.createdAt),
                ),
                _Field(
                  icon: Icons.access_time_rounded,
                  label: l10n.t('profileLastSeen'),
                  value: _fmt(user?.lastSeenAt),
                ),
              ];
              if (!two) {
                return Column(
                  children: children
                      .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 14), child: w))
                      .toList(),
                );
              }
              return Wrap(
                spacing: 24,
                runSpacing: 18,
                children: [for (final c in children) SizedBox(width: 240, child: c)],
              );
            },
          ),
        ],
      ),
    );
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
                      Text(
                        AuthController.instance.hubInfo?.houseName ?? 'GateKeeper Hub',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${ApiConfig.baseUrl ?? '—'} • ${l10n.t('onlineNow')}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                //Pulsante che porta alla sezione "Connettività" delle impostazioni
                //per gestire l'hub corrente (cambia / disconnetti / riconnetti).
                GKButton(
                  onPressed: () => context.go('/settings'),
                  label: l10n.t('manage'),
                  icon: Icons.tune_rounded,
                  variant: GKButtonVariant.ghost,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Email Verification Card
// ─────────────────────────────────────────────────────────────────────────────
class _EmailVerificationCard extends StatefulWidget {
  const _EmailVerificationCard({required this.auth});
  final AuthController auth;

  @override
  State<_EmailVerificationCard> createState() => _EmailVerificationCardState();
}

class _EmailVerificationCardState extends State<_EmailVerificationCard> {
  bool _sending = false;
  bool _codeSent = false;
  bool _verifying = false;
  String? _error;
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() { _sending = true; _error = null; });
    try {
      await GateKeeperApi.instance.auth.sendEmailCode();
      setState(() { _codeSent = true; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _sending = false; });
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) return;
    setState(() { _verifying = true; _error = null; });
    try {
      await GateKeeperApi.instance.auth.verifyEmail(code);
      // Ricarica l'utente per aggiornare lo stato.
      await widget.auth.refreshUser();
      if (mounted) {
        final l10n = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('verifyEmailSuccess'))),
        );
        setState(() { _codeSent = false; _codeCtrl.clear(); });
      }
    } catch (e) {
      setState(() { _error = AppL10n.of(context).t('verifyEmailError'); });
    } finally {
      setState(() { _verifying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final user = widget.auth.user;
    // Considera verificata se il campo non esiste (utenti pre-feature).
    final verified = user == null || (user.emailVerified ?? true);

    if (verified) {
      return GKCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        background: AppColors.success.withValues(alpha: 0.06),
        borderColor: AppColors.success.withValues(alpha: 0.18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.t('emailVerified').toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      background: AppColors.orangeGold.withValues(alpha: 0.06),
      borderColor: AppColors.orangeGold.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orangeGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.orangeGold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('verifyEmail').toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.orangeGold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      l10n.t('verifyEmailSubtitle'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          if (!_codeSent)
            GKButton(
              onPressed: _sending ? null : _sendCode,
              icon: Icons.send_rounded,
              label: _sending ? l10n.t('verifyEmailSending') : l10n.t('verifyEmailSend'),
              variant: GKButtonVariant.primary,
              expanded: true,
            )
          else ...[
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: l10n.t('verifyEmailCodeHint'),
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GKButton(
                    onPressed: _verifying ? null : _verify,
                    icon: Icons.check_circle_rounded,
                    label: l10n.t('verifyEmailConfirm'),
                    variant: GKButtonVariant.primary,
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 10),
                GKButton(
                  onPressed: _sending ? null : _sendCode,
                  icon: Icons.refresh_rounded,
                  label: '',
                  variant: GKButtonVariant.ghost,
                  dense: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
