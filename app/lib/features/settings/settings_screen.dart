import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gk_badge.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';

// ---------------------------------------------------------------------------
// Enum sezioni settings (sub-navigation)
// ---------------------------------------------------------------------------

/// Sezioni disponibili nel pannello impostazioni.
///
/// Usato sia per la sub-nav laterale (desktop) che per il menu a lista (mobile).
enum _SettingsSection {
  alertRules,
  gatewayDevice,
  rfidBle,
  myAccount,
  appearance,
  dataPrivacy,
}

/// Metadati di ogni sezione: icona e label.
extension _SettingsSectionMeta on _SettingsSection {
  IconData get icon => switch (this) {
        _SettingsSection.alertRules    => Icons.notifications_active_outlined,
        _SettingsSection.gatewayDevice => Icons.router_outlined,
        _SettingsSection.rfidBle       => Icons.sensors_outlined,
        _SettingsSection.myAccount     => Icons.person_outline,
        _SettingsSection.appearance    => Icons.palette_outlined,
        _SettingsSection.dataPrivacy   => Icons.shield_outlined,
      };

  String get label => switch (this) {
        _SettingsSection.alertRules    => 'Alert Rules',
        _SettingsSection.gatewayDevice => 'Gateway Device',
        _SettingsSection.rfidBle       => 'RFID & BLE',
        _SettingsSection.myAccount     => 'My Account',
        _SettingsSection.appearance    => 'Appearance',
        _SettingsSection.dataPrivacy   => 'Data & Privacy',
      };
}

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

/// Schermata impostazioni con sub-navigation laterale (desktop) o a lista (mobile).
///
/// Layout desktop:
/// - Colonna sinistra (240px): menu sezioni con highlight animato
/// - Area destra: contenuto della sezione selezionata
///
/// Layout mobile:
/// - Lista compatta delle sezioni, tap apre la sezione inline.
///
/// Sezioni disponibili:
/// 1. Alert Rules — regole di notifica e alert critico
/// 2. Gateway Device — IP, tunnel, restart
/// 3. RFID & BLE — calibrazione sensori
/// 4. My Account — avatar, nome, password
/// 5. Appearance — tema, lingua
/// 6. Data & Privacy — export, reset dati
///
/// TODO: collegare toggle e campi al backend /api/settings.
/// TODO: implementare persistenza locale con SharedPreferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection _activeSection = _SettingsSection.alertRules;

  // ── Stato toggle notifiche ─────────────────────────────────────────────────
  // TODO: caricare da SharedPreferences / GET /api/settings all'avvio
  bool _notifEntry         = true;
  bool _notifExit          = true;
  bool _notifAlert         = true;
  bool _notifForgotten     = true;
  bool _notifUnauthorized  = true;
  bool _notifQuietHours    = false;
  bool _alertUnauthorized  = true;
  bool _alertForgottenEssentials = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppBreakpoints.desktop;

        return SafeArea(
          child: isDesktop
              ? _DesktopLayout(
                  activeSection: _activeSection,
                  onSectionChanged: (s) =>
                      setState(() => _activeSection = s),
                  content: _buildSectionContent(context),
                )
              : _MobileLayout(
                  activeSection: _activeSection,
                  onSectionChanged: (s) =>
                      setState(() => _activeSection = s),
                  content: _buildSectionContent(context),
                ),
        );
      },
    );
  }

  /// Costruisce il widget del contenuto per la sezione attiva.
  Widget _buildSectionContent(BuildContext context) {
    return switch (_activeSection) {
      _SettingsSection.alertRules    => _AlertRulesContent(
          alertUnauthorized: _alertUnauthorized,
          onAlertUnauthorized: (v) =>
              setState(() => _alertUnauthorized = v),
          alertForgotten: _alertForgottenEssentials,
          onAlertForgotten: (v) =>
              setState(() => _alertForgottenEssentials = v),
          quietHours: _notifQuietHours,
          onQuietHours: (v) =>
              setState(() => _notifQuietHours = v),
        ),
      _SettingsSection.gatewayDevice => _GatewayDeviceContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      _SettingsSection.rfidBle       => _RfidBleContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      _SettingsSection.myAccount     => _MyAccountContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      _SettingsSection.appearance    => _AppearanceContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      _SettingsSection.dataPrivacy   => _DataPrivacyContent(
          onAction: (msg) => _todoSnack(context, msg),
          notifEntry: _notifEntry,
          onNotifEntry: (v) => setState(() => _notifEntry = v),
          notifExit: _notifExit,
          onNotifExit: (v) => setState(() => _notifExit = v),
          notifAlert: _notifAlert,
          onNotifAlert: (v) => setState(() => _notifAlert = v),
          notifForgotten: _notifForgotten,
          onNotifForgotten: (v) => setState(() => _notifForgotten = v),
          notifUnauthorized: _notifUnauthorized,
          onNotifUnauthorized: (v) =>
              setState(() => _notifUnauthorized = v),
        ),
    };
  }

  void _todoSnack(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout desktop: sidebar sinistra + area contenuto
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.activeSection,
    required this.onSectionChanged,
    required this.content,
  });

  final _SettingsSection activeSection;
  final ValueChanged<_SettingsSection> onSectionChanged;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sub-nav sinistra ────────────────────────────────────────────────
        Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text('SETTINGS', style: AppTextStyles.label),
              ),
              ...(_SettingsSection.values.map(
                (section) => _SubNavItem(
                  section: section,
                  isActive: section == activeSection,
                  onTap: () => onSectionChanged(section),
                ),
              )),
            ],
          ),
        ),
        // ── Contenuto sezione ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo sezione corrente
                Text(
                  activeSection.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 20),
                content,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Layout mobile: header + contenuto scroll
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.activeSection,
    required this.onSectionChanged,
    required this.content,
  });

  final _SettingsSection activeSection;
  final ValueChanged<_SettingsSection> onSectionChanged;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Settings'),
          // Chip sezioni a scorrimento orizzontale
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _SettingsSection.values.map((section) {
                final active = section == activeSection;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSectionChanged(section),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.stormyTeal
                            : AppColors.panelSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? AppColors.stormyTeal
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            section.icon,
                            size: 14,
                            color: active
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            section.label,
                            style: TextStyle(
                              color: active
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-nav item (usato nel desktop layout)
// ---------------------------------------------------------------------------

/// Voce della sub-navigazione sinistra nelle Settings (solo desktop).
///
/// Parametri:
/// - [section]: la sezione che rappresenta
/// - [isActive]: se è la sezione correntemente selezionata
/// - [onTap]: callback al tap
class _SubNavItem extends StatelessWidget {
  const _SubNavItem({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final _SettingsSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          // L'item attivo ha un background teal semi-trasparente
          color: isActive
              ? AppColors.stormyTeal.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              section.icon,
              size: 17,
              color: isActive
                  ? AppColors.stormyTealBright
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              section.label,
              style: TextStyle(
                color: isActive
                    ? AppColors.stormyTealBright
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// CONTENUTI SEZIONI
// ===========================================================================

// ---------------------------------------------------------------------------
// 1. Alert Rules
// ---------------------------------------------------------------------------

/// Sezione Alert Rules: regole di notifica + gateway config.
///
/// Parametri bool con relativi callback per gestire lo stato nel parent.
class _AlertRulesContent extends StatelessWidget {
  const _AlertRulesContent({
    required this.alertUnauthorized,
    required this.onAlertUnauthorized,
    required this.alertForgotten,
    required this.onAlertForgotten,
    required this.quietHours,
    required this.onQuietHours,
  });

  final bool alertUnauthorized;
  final ValueChanged<bool> onAlertUnauthorized;
  final bool alertForgotten;
  final ValueChanged<bool> onAlertForgotten;
  final bool quietHours;
  final ValueChanged<bool> onQuietHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descrizione sezione
        const Text(
          'Configure when GateKeeper should send notifications or trigger critical alerts.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Card regole alert
        GlassCard(
          child: Column(
            children: [
              // Toggle: unauthorized exit alert
              _AlertRuleRow(
                title: 'Unauthorized Exit Alerts',
                subtitle:
                    'Trigger a CRITICAL alert if an object passes the gateway without an authenticated user (BLE) nearby.',
                value: alertUnauthorized,
                onChanged: onAlertUnauthorized,
              ),
              const Divider(color: AppColors.border),
              // Toggle: forgotten essential items
              _AlertRuleRow(
                title: 'Forgotten Essential Items',
                subtitle:
                    'Notify the user if they leave without objects tagged as "Essentials" (e.g., Keys, Wallet).',
                value: alertForgotten,
                onChanged: onAlertForgotten,
              ),
              const Divider(color: AppColors.border),
              // Toggle: quiet hours
              _AlertRuleRow(
                title: 'Quiet Hours',
                subtitle:
                    'Mute all non-critical notifications during specific hours.',
                value: quietHours,
                onChanged: onQuietHours,
              ),
              // Selettori orari quiet (visibili solo se quiet hours è attivo)
              if (quietHours)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(0, 8, 0, 4),
                  child: Row(
                    children: [
                      // TODO: implementare TimePickerDialog
                      _TimeChip(label: '10:00 PM'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ),
                      _TimeChip(label: '07:00 AM'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Riga con toggle per una regola di alert.
class _AlertRuleRow extends StatelessWidget {
  const _AlertRuleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.stormyTealBright,
          ),
        ],
      ),
    );
  }
}

/// Chip selettore orario (stub — TODO: aprire TimePickerDialog).
class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Gateway Device
// ---------------------------------------------------------------------------

/// Sezione Gateway Device: stato dispositivo, IP, Cloudflare, restart.
class _GatewayDeviceContent extends StatelessWidget {
  const _GatewayDeviceContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage your Raspberry Pi gateway and network settings.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsTile(
                label: 'Gateway IP / Hostname',
                subtitle: '192.168.1.100',
                icon: Icons.dns_outlined,
                onTap: () => onAction('Edit Gateway IP'),
              ),
              SettingsTile(
                label: 'Cloudflare Tunnel',
                subtitle: 'Active — gatekeeper.yourdomain.com',
                icon: Icons.cloud_outlined,
                trailing: const GkBadge(
                    label: 'Active', color: AppColors.success),
              ),
              SettingsTile(
                label: 'Network Settings',
                subtitle: 'Wi-Fi · LAN configuration',
                icon: Icons.wifi_outlined,
                onTap: () => onAction('Network Settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Card gateway online con azioni
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.stormyTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.router_outlined,
                        color: AppColors.stormyTealBright, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Main Entry Gateway',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'IP: 192.168.1.100 · Uptime: 45 days',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const GkBadge(
                      label: 'Online', color: AppColors.success),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // TODO: chiamare POST /api/gateway/restart
                  ElevatedButton.icon(
                    onPressed: () => onAction('Restart Gateway'),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Restart Gateway'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.inkBlack,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => onAction('Network Settings'),
                    icon: const Icon(Icons.wifi, size: 16),
                    label: const Text('Network Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. RFID & BLE
// ---------------------------------------------------------------------------

/// Sezione RFID & BLE: stato reader, calibrazione range scanner.
class _RfidBleContent extends StatelessWidget {
  const _RfidBleContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adjust sensor ranges and read intervals to prevent false positives.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsTile(
                label: 'RFID Reader',
                subtitle: 'USB · Connected',
                icon: Icons.sensors_outlined,
                trailing: const GkBadge(
                    label: 'Online', color: AppColors.success),
              ),
              SettingsTile(
                label: 'BLE Scanner',
                subtitle: 'Raspberry Pi onboard',
                icon: Icons.bluetooth_outlined,
                trailing: const GkBadge(
                    label: 'Online', color: AppColors.success),
              ),
              SettingsTile(
                label: 'BLE Detection Radius',
                subtitle: 'Medium (5m) — recommended',
                icon: Icons.radar_outlined,
                onTap: () => onAction('BLE Detection Radius'),
              ),
              SettingsTile(
                label: 'RFID Read Interval',
                subtitle: 'Every 500ms',
                icon: Icons.timer_outlined,
                onTap: () => onAction('RFID Read Interval'),
              ),
              SettingsTile(
                label: 'Test RFID Scan',
                subtitle: 'Verifica che il reader risponda correttamente',
                icon: Icons.nfc_outlined,
                onTap: () => onAction('Test RFID Scan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. My Account
// ---------------------------------------------------------------------------

/// Sezione My Account: avatar, nome, email, cambio password.
class _MyAccountContent extends StatelessWidget {
  const _MyAccountContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card profilo con avatar
        GlassCard(
          child: Row(
            children: [
              // Avatar utente
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.orange.withValues(alpha: 0.2),
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Alice Rossi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'alice@home.local · Admin',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => onAction('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.stormyTealBright,
                  side: const BorderSide(
                      color: AppColors.stormyTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsTile(
                label: 'Change Password',
                icon: Icons.lock_outline,
                onTap: () => onAction('Change Password'),
              ),
              SettingsTile(
                label: 'Active Sessions',
                subtitle: '2 dispositivi attivi',
                icon: Icons.devices_outlined,
                onTap: () => onAction('Active Sessions'),
              ),
              SettingsTile(
                label: 'Two-Factor Authentication',
                subtitle: 'Not configured',
                icon: Icons.security_outlined,
                onTap: () => onAction('2FA Setup'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Appearance
// ---------------------------------------------------------------------------

/// Sezione Appearance: tema, lingua.
class _AppearanceContent extends StatelessWidget {
  const _AppearanceContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SettingsTile(
            label: 'Theme',
            subtitle: 'Dark (default)',
            icon: Icons.dark_mode_outlined,
            // TODO: aggiungere light theme e toggle
            onTap: () => onAction('Theme selector'),
          ),
          SettingsTile(
            label: 'Language',
            subtitle: 'English',
            icon: Icons.language_outlined,
            // TODO: flutter_localizations
            onTap: () => onAction('Language selector'),
          ),
          SettingsTile(
            label: 'About GateKeeper',
            subtitle: 'v0.1.0-alpha — Smart tag, safe exit',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Data & Privacy (contiene anche i toggle notifiche)
// ---------------------------------------------------------------------------

/// Sezione Data & Privacy + Notification preferences.
class _DataPrivacyContent extends StatelessWidget {
  const _DataPrivacyContent({
    required this.onAction,
    required this.notifEntry,
    required this.onNotifEntry,
    required this.notifExit,
    required this.onNotifExit,
    required this.notifAlert,
    required this.onNotifAlert,
    required this.notifForgotten,
    required this.onNotifForgotten,
    required this.notifUnauthorized,
    required this.onNotifUnauthorized,
  });

  final ValueChanged<String> onAction;
  final bool notifEntry;
  final ValueChanged<bool> onNotifEntry;
  final bool notifExit;
  final ValueChanged<bool> onNotifExit;
  final bool notifAlert;
  final ValueChanged<bool> onNotifAlert;
  final bool notifForgotten;
  final ValueChanged<bool> onNotifForgotten;
  final bool notifUnauthorized;
  final ValueChanged<bool> onNotifUnauthorized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preferenze notifiche push
        const Text('PUSH NOTIFICATIONS', style: AppTextStyles.label),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsTile(
                label: 'Entry events',
                icon: Icons.login_outlined,
                trailing: Switch.adaptive(
                  value: notifEntry,
                  onChanged: onNotifEntry,
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Exit events',
                icon: Icons.logout_outlined,
                trailing: Switch.adaptive(
                  value: notifExit,
                  onChanged: onNotifExit,
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Alerts',
                subtitle: 'Child unaccompanied, unusual events',
                icon: Icons.warning_amber_outlined,
                trailing: Switch.adaptive(
                  value: notifAlert,
                  onChanged: onNotifAlert,
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Forgotten items',
                icon: Icons.inventory_2_outlined,
                trailing: Switch.adaptive(
                  value: notifForgotten,
                  onChanged: onNotifForgotten,
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Unauthorized exits',
                icon: Icons.no_encryption_outlined,
                trailing: Switch.adaptive(
                  value: notifUnauthorized,
                  onChanged: onNotifUnauthorized,
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Azioni dati
        const Text('DATA', style: AppTextStyles.label),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsTile(
                label: 'Export Event Logs',
                subtitle: 'Scarica CSV di tutti gli eventi',
                icon: Icons.download_outlined,
                onTap: () => onAction('Export Event Logs'),
              ),
              SettingsTile(
                label: 'Reset All Data',
                subtitle: 'Cancella tutti gli eventi e gli oggetti',
                icon: Icons.delete_outline,
                labelColor: AppColors.error,
                onTap: () => onAction('Reset All Data — requires confirm'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
