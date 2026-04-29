import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/gk_badge.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

/// Schermata impostazioni dell'app e del gateway.
///
/// Organizzata in sezioni logiche:
/// 1. Gateway — IP, stato connessione Cloudflare Tunnel;
/// 2. Notifications — preferenze notifiche;
/// 3. Appearance — tema, lingua;
/// 4. Security — logout, reset;
/// 5. About — versione, info progetto.
///
/// TODO: collegare i toggle a SharedPreferences o al backend.
/// TODO: implementare dialog di conferma per azioni distruttive (es. Reset).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Stato locale dei toggle
  // TODO: caricare da SharedPreferences all'avvio
  bool _notifEntry = true;
  bool _notifExit = true;
  bool _notifAlert = true;
  bool _notifForgotten = true;
  bool _notifUnauthorized = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              0,
              isMobile ? 16 : 24,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(title: 'Settings'),

                // SEZIONE 1 – Gateway
                SettingsSection(
                  title: 'Gateway',
                  icon: Icons.router_outlined,
                  children: [
                    SettingsTile(
                      label: 'Gateway IP / Hostname',
                      subtitle: '192.168.1.100',
                      icon: Icons.dns_outlined,
                      // TODO: aprire dialog edit hostname
                      onTap: () => _todoSnack(context, 'Edit Gateway IP'),
                    ),
                    SettingsTile(
                      label: 'Cloudflare Tunnel',
                      subtitle: 'Active — gatekeeper.yourdomain.com',
                      icon: Icons.cloud_outlined,
                      trailing: const GkBadge(
                        label: 'Active',
                        color: AppColors.success,
                      ),
                    ),
                    SettingsTile(
                      label: 'RFID Reader',
                      subtitle: 'USB · Connected',
                      icon: Icons.sensors_outlined,
                      trailing: const GkBadge(
                        label: 'Online',
                        color: AppColors.success,
                      ),
                    ),
                    SettingsTile(
                      label: 'BLE Scanner',
                      subtitle: 'Raspberry Pi onboard',
                      icon: Icons.bluetooth_outlined,
                      trailing: const GkBadge(
                        label: 'Online',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SEZIONE 2 – Notifications
                SettingsSection(
                  title: 'Notifications',
                  icon: Icons.notifications_none_outlined,
                  children: [
                    SettingsTile(
                      label: 'Entry events',
                      icon: Icons.login_outlined,
                      trailing: Switch.adaptive(
                        value: _notifEntry,
                        onChanged: (v) =>
                            setState(() => _notifEntry = v),
                        activeColor: AppColors.stormyTealBright,
                      ),
                    ),
                    SettingsTile(
                      label: 'Exit events',
                      icon: Icons.logout_outlined,
                      trailing: Switch.adaptive(
                        value: _notifExit,
                        onChanged: (v) =>
                            setState(() => _notifExit = v),
                        activeColor: AppColors.stormyTealBright,
                      ),
                    ),
                    SettingsTile(
                      label: 'Alerts',
                      subtitle: 'Child unaccompanied, unusual events',
                      icon: Icons.warning_amber_outlined,
                      trailing: Switch.adaptive(
                        value: _notifAlert,
                        onChanged: (v) =>
                            setState(() => _notifAlert = v),
                        activeColor: AppColors.stormyTealBright,
                      ),
                    ),
                    SettingsTile(
                      label: 'Forgotten items',
                      icon: Icons.inventory_2_outlined,
                      trailing: Switch.adaptive(
                        value: _notifForgotten,
                        onChanged: (v) =>
                            setState(() => _notifForgotten = v),
                        activeColor: AppColors.stormyTealBright,
                      ),
                    ),
                    SettingsTile(
                      label: 'Unauthorized exits',
                      icon: Icons.no_encryption_outlined,
                      trailing: Switch.adaptive(
                        value: _notifUnauthorized,
                        onChanged: (v) =>
                            setState(() => _notifUnauthorized = v),
                        activeColor: AppColors.stormyTealBright,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SEZIONE 3 – Appearance
                SettingsSection(
                  title: 'Appearance',
                  icon: Icons.palette_outlined,
                  children: [
                    SettingsTile(
                      label: 'Theme',
                      subtitle: 'Dark (default)',
                      icon: Icons.dark_mode_outlined,
                      // TODO: aggiungere light theme e toggle
                      onTap: () => _todoSnack(context, 'Theme selector'),
                    ),
                    SettingsTile(
                      label: 'Language',
                      subtitle: 'English',
                      icon: Icons.language_outlined,
                      // TODO: aggiungere localizzazione (flutter_localizations)
                      onTap: () => _todoSnack(context, 'Language selector'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SEZIONE 4 – Security
                SettingsSection(
                  title: 'Security',
                  icon: Icons.security_outlined,
                  children: [
                    SettingsTile(
                      label: 'Change Password',
                      icon: Icons.lock_outline,
                      onTap: () =>
                          _todoSnack(context, 'Change password dialog'),
                    ),
                    SettingsTile(
                      label: 'Active Sessions',
                      icon: Icons.devices_outlined,
                      onTap: () =>
                          _todoSnack(context, 'Active sessions view'),
                    ),
                    SettingsTile(
                      label: 'Sign Out',
                      icon: Icons.logout,
                      labelColor: AppColors.orange,
                      onTap: () =>
                          _todoSnack(context, 'Sign out flow — Blocco 2B'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SEZIONE 5 – About
                SettingsSection(
                  title: 'About',
                  icon: Icons.info_outline,
                  children: [
                    const SettingsTile(
                      label: 'Version',
                      subtitle: '0.1.0-alpha (Block 2A)',
                      icon: Icons.tag_outlined,
                    ),
                    const SettingsTile(
                      label: 'Project',
                      subtitle: 'GateKeeper IoT — Smart tag, safe exit.',
                      icon: Icons.door_front_door_outlined,
                    ),
                    SettingsTile(
                      label: 'GitHub Repository',
                      subtitle: 'ScalabrinSimone/GateKeeper',
                      icon: Icons.code_outlined,
                      onTap: () =>
                          _todoSnack(context, 'Open GitHub URL'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mostra uno snackbar temporaneo per feature non ancora implementate.
  void _todoSnack(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming in Block 2B'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
