import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_config.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/gatekeeper_api.dart';
import '../../data/services/push_notifications_service.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';
import '../auth/widgets/gk_text_field.dart';

//Vista impostazioni con sezioni: preferenze, connettività, notifiche, account, sistema.
//Le azioni reali (logout, factory reset, generazione inviti) sono cablate
//all'AuthController e all'API.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings, required this.auth});

  final SettingsController settings;
  final AuthController auth;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _resetting = false;
  bool _applyingRemote = false;
  late final TextEditingController _remoteCtrl;

  @override
  void initState() {
    super.initState();
    _remoteCtrl = TextEditingController(text: widget.settings.remoteTunnelUrl ?? '');
  }

  @override
  void dispose() {
    _remoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyRemote(AppL10n l10n) async {
    final url = _remoteCtrl.text.trim();
    if (url.isEmpty || !(url.startsWith('http://') || url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('invalidUrl'))),
      );
      return;
    }
    setState(() => _applyingRemote = true);
    try {
      await widget.settings.setRemoteTunnelUrl(url);
      await widget.auth.useBaseUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('remoteApplied'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _applyingRemote = false);
    }
  }

  Future<void> _saveRemote(AppL10n l10n) async {
    await widget.settings.setRemoteTunnelUrl(_remoteCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('remoteSave'))),
    );
  }

  Future<void> _clearRemote(AppL10n l10n) async {
    await widget.settings.setRemoteTunnelUrl(null);
    setState(() => _remoteCtrl.clear());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('remoteCleared'))),
    );
  }

  //Riconnette l'app all'hub corrente: forza un re-bootstrap di AuthController.
  //Utile dopo un cambio di rete o per uscire dallo stato "offline".
  Future<void> _reconnectHub(AppL10n l10n) async {
    await widget.auth.bootstrap();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('reconnectingHub'))),
    );
  }

  //"Esci dalla casa": rimuove il base URL configurato e ogni token salvato,
  //riportando l'app alla schermata di scelta hub. NON tocca i dati sul
  //Raspberry: serve solo a "smettere di usare quella casa" da questo
  //dispositivo. Per cancellare l'hub usare invece il factory reset.
  Future<void> _leaveHome(AppL10n l10n) async {
    final ok = await _confirm(
      title: l10n.t('leaveHomeTitle'),
      body: l10n.t('leaveHomeBody'),
      confirmLabel: l10n.t('leaveHome'),
      danger: true,
    );
    if (!ok) return;
    await widget.auth.leaveHome();
    if (!mounted) return;
    context.go('/welcome');
  }

  Future<void> _togglePush(bool value, AppL10n l10n) async {
    await widget.settings.setPushEnabled(value);
    if (value) {
      final ok = await PushNotificationsService.instance.initialize();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('pushUnsupported'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('pushRegistered'))),
        );
      }
    } else {
      await PushNotificationsService.instance.revoke();
    }
  }

  Future<void> _doLogout(AppL10n l10n) async {
    final ok = await _confirm(
      title: l10n.t('logout'),
      body: l10n.t('logoutConfirm'),
      confirmLabel: l10n.t('logout'),
      danger: true,
    );
    if (!ok) return;
    await widget.auth.logout();
    if (!mounted) return;
    context.go('/welcome');
  }

  Future<void> _doFactoryReset(AppL10n l10n) async {
    if (!widget.auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('factoryResetAdminOnly'))),
      );
      return;
    }
    final ok = await _confirm(
      title: l10n.t('factoryResetTitle'),
      body: l10n.t('factoryResetConfirm'),
      confirmLabel: l10n.t('factoryResetTitle'),
      danger: true,
    );
    if (!ok) return;

    setState(() => _resetting = true);
    try {
      await widget.auth.factoryReset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('factoryResetDone'))),
      );
      context.go('/welcome');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _generateInvite(AppL10n l10n) async {
    final role = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.t('generateInvite'),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              for (final r in ['admin', 'adult', 'child'])
                ListTile(
                  leading: Icon(_roleIcon(r), color: AppColors.stormyTeal),
                  title: Text(r.toUpperCase()),
                  onTap: () => Navigator.of(ctx).pop(r),
                ),
            ],
          ),
        ),
      ),
    );
    if (role == null) return;

    try {
      final inv = await GateKeeperApi.instance.invites.create(role: role);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.t('generateInvite')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.t('role')}: ${inv.role.toUpperCase()}'),
              const SizedBox(height: 8),
              SelectableText(inv.token, style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n.t('copyCode')),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inv.token));
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.t('copiedToClipboard'))),
                  );
                }
              },
            ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.t('close'))),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.shield_rounded;
      case 'child':
        return Icons.child_care_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final l10n = AppL10n.of(context);
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger ? AppColors.danger : AppColors.stormyTeal,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final settings = widget.settings;
    final hub = widget.auth.hubInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.t('settings'),
            subtitle: l10n.t('configureHub'),
          ),
          _Section(
            title: l10n.t('appPreferences'),
            children: [
              _Tile(
                icon: Icons.palette_rounded,
                title: l10n.t('theme'),
                subtitle: settings.isDark ? l10n.t('darkMode') : l10n.t('lightMode'),
                trailing: _ToggleChips(
                  left: 'Light',
                  right: 'Dark',
                  selected: settings.isDark ? 1 : 0,
                  onChanged: (i) {
                    if ((i == 1) != settings.isDark) settings.toggleTheme();
                  },
                ),
              ),
              _Tile(
                icon: Icons.translate_rounded,
                title: l10n.t('language'),
                subtitle: l10n.languageCode == 'it' ? l10n.t('italian') : l10n.t('english'),
                trailing: _ToggleChips(
                  left: 'IT',
                  right: 'EN',
                  selected: l10n.languageCode == 'en' ? 1 : 0,
                  onChanged: (i) => settings.setLocale(Locale(i == 0 ? 'it' : 'en')),
                ),
              ),
            ],
          ),
          _Section(
            title: l10n.t('connectivity'),
            children: [
              //Stato attuale: house name + URL, ben visibile in alto.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi_tethering_rounded,
                          color: AppColors.success, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hub?.houseName ?? l10n.t('houseLabel'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ApiConfig.baseUrl ?? '—',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _Tile(
                icon: Icons.router_rounded,
                title: l10n.t('changeHubTitle'),
                subtitle: l10n.t('changeHubSubtitle'),
                trailing: GKButton(
                  onPressed: () => context.go('/onboarding/discover'),
                  label: l10n.t('changeHub'),
                  variant: GKButtonVariant.ghost,
                  dense: true,
                ),
              ),
              _Tile(
                icon: Icons.sync_rounded,
                title: l10n.t('reconnectHubTitle'),
                subtitle: l10n.t('reconnectHubSubtitle'),
                trailing: GKButton(
                  onPressed: () => _reconnectHub(l10n),
                  label: l10n.t('reconnect'),
                  variant: GKButtonVariant.secondary,
                  dense: true,
                ),
              ),
              _Tile(
                icon: Icons.exit_to_app_rounded,
                title: l10n.t('leaveHomeTitle'),
                subtitle: l10n.t('leaveHomeSubtitle'),
                trailing: GKButton(
                  onPressed: () => _leaveHome(l10n),
                  label: l10n.t('leaveHome'),
                  variant: GKButtonVariant.danger,
                  dense: true,
                ),
              ),
            ],
          ),
          _Section(
            title: l10n.t('notificationsAlerts'),
            children: [
              _Tile(
                icon: Icons.notifications_active_rounded,
                title: l10n.t('pushTitle'),
                subtitle: l10n.t('pushSubtitle'),
                trailing: Switch.adaptive(
                  value: widget.settings.pushEnabled,
                  activeThumbColor: AppColors.stormyTeal,
                  onChanged: (v) => _togglePush(v, l10n),
                ),
              ),
            ],
          ),
          //Sezione Accesso remoto: l'utente può salvare l'URL di un tunnel
          //(es. Cloudflare Tunnel) per accedere all'hub anche fuori casa.
          _Section(
            title: l10n.t('remoteAccessTitle'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Text(
                  l10n.t('remoteAccessExplain'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: GKTextField(
                  controller: _remoteCtrl,
                  label: l10n.t('remoteUrlLabel'),
                  prefixIcon: Icons.cloud_rounded,
                  keyboardType: TextInputType.url,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GKButton(
                      onPressed: _applyingRemote ? null : () => _applyRemote(l10n),
                      label: _applyingRemote ? l10n.t('loadingDots') : l10n.t('remoteApply'),
                      icon: Icons.bolt_rounded,
                      variant: GKButtonVariant.secondary,
                      dense: true,
                    ),
                    GKButton(
                      onPressed: () => _saveRemote(l10n),
                      label: l10n.t('remoteSave'),
                      icon: Icons.save_rounded,
                      variant: GKButtonVariant.outline,
                      dense: true,
                    ),
                    GKButton(
                      onPressed: () => _clearRemote(l10n),
                      label: l10n.t('remoteClear'),
                      icon: Icons.delete_outline_rounded,
                      variant: GKButtonVariant.ghost,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.auth.isAdmin)
            _Section(
              title: l10n.t('invites'),
              children: [
                _Tile(
                  icon: Icons.person_add_alt_rounded,
                  title: l10n.t('inviteMember'),
                  subtitle: l10n.t('manageInvites'),
                  trailing: GKButton(
                    onPressed: () => _generateInvite(l10n),
                    label: l10n.t('generateInvite'),
                    variant: GKButtonVariant.secondary,
                    dense: true,
                  ),
                ),
              ],
            ),
          _Section(
            title: l10n.t('account'),
            children: [
              _Tile(
                icon: Icons.logout_rounded,
                title: l10n.t('logoutTitle'),
                subtitle: l10n.t('logoutSubtitle'),
                trailing: GKButton(
                  onPressed: () => _doLogout(l10n),
                  label: l10n.t('logout'),
                  variant: GKButtonVariant.ghost,
                  dense: true,
                ),
              ),
              if (widget.auth.isAdmin)
                _Tile(
                  icon: Icons.delete_forever_rounded,
                  title: l10n.t('factoryResetTitle'),
                  subtitle: l10n.t('factoryResetSubtitle'),
                  trailing: GKButton(
                    onPressed: _resetting ? null : () => _doFactoryReset(l10n),
                    label: l10n.t('factoryResetTitle'),
                    variant: GKButtonVariant.danger,
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.stormyTeal,
              ),
            ),
          ),
          GKCard(
            borderRadius: 28,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stormyTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.stormyTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleChips extends StatelessWidget {
  const _ToggleChips({required this.left, required this.right, required this.selected, required this.onChanged});

  final String left;
  final String right;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.stormyTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(context, left, selected == 0, () => onChanged(0)),
          _chip(context, right, selected == 1, () => onChanged(1)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool active, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.stormyTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
