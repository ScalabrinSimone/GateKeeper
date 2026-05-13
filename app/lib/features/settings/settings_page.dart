import 'package:flutter/material.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';

//Vista impostazioni con 4 sezioni: preferenze, connettività, notifiche, sistema.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushOn = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final settings = widget.settings;

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
              _Tile(
                icon: Icons.bluetooth_rounded,
                title: l10n.t('raspberryPairing'),
                subtitle: 'BLE • OK',
                trailing: GKButton(onPressed: () {}, label: l10n.t('pair'), variant: GKButtonVariant.ghost, dense: true),
              ),
              _Tile(
                icon: Icons.wifi_rounded,
                title: l10n.t('wifiHome'),
                subtitle: 'Home_Fastweb_Gate',
                trailing: GKButton(onPressed: () {}, label: l10n.t('edit'), variant: GKButtonVariant.ghost, dense: true),
              ),
            ],
          ),
          _Section(
            title: l10n.t('notificationsAlerts'),
            children: [
              _Tile(
                icon: Icons.notifications_active_rounded,
                title: l10n.t('pushNotifications'),
                subtitle: l10n.t('activeNotifications'),
                trailing: Switch.adaptive(
                  value: _pushOn,
                  activeThumbColor: AppColors.stormyTeal,
                  onChanged: (v) => setState(() => _pushOn = v),
                ),
              ),
              _Tile(
                icon: Icons.volume_up_rounded,
                title: l10n.t('audioHub'),
                subtitle: l10n.t('doorBeeper'),
                trailing: GKButton(onPressed: () {}, label: l10n.t('test'), variant: GKButtonVariant.ghost, dense: true),
              ),
            ],
          ),
          _Section(
            title: l10n.t('system'),
            children: [
              _Tile(
                icon: Icons.storage_rounded,
                title: l10n.t('databaseBackup'),
                subtitle: l10n.t('lastBackup'),
                trailing: GKButton(onPressed: () {}, label: l10n.t('sync'), variant: GKButtonVariant.ghost, dense: true),
              ),
              _Tile(
                icon: Icons.memory_rounded,
                title: l10n.t('firmware'),
                subtitle: 'v1.4.2',
                trailing: GKButton(onPressed: () {}, label: l10n.t('update'), variant: GKButtonVariant.ghost, dense: true),
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
