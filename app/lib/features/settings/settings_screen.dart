import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
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
/// Usato sia per la sub-nav laterale (desktop) che per il menu a chip (mobile).
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
        _SettingsSection.alertRules => Icons.notifications_active_outlined,
        _SettingsSection.gatewayDevice => Icons.router_outlined,
        _SettingsSection.rfidBle => Icons.sensors_outlined,
        _SettingsSection.myAccount => Icons.person_outline,
        _SettingsSection.appearance => Icons.palette_outlined,
        _SettingsSection.dataPrivacy => Icons.shield_outlined,
      };

  String get label => switch (this) {
        _SettingsSection.alertRules => 'Alert Rules',
        _SettingsSection.gatewayDevice => 'Gateway Device',
        _SettingsSection.rfidBle => 'RFID & BLE',
        _SettingsSection.myAccount => 'My Account',
        _SettingsSection.appearance => 'Appearance',
        _SettingsSection.dataPrivacy => 'Data & Privacy',
      };
}

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

/// Schermata impostazioni con sub-navigation laterale (desktop) o chip (mobile).
///
/// Layout desktop:
/// - Colonna sinistra (220px): menu sezioni con highlight animato
/// - Area destra: contenuto della sezione selezionata
///
/// Layout mobile:
/// - Chip scorrevoli orizzontalmente, contenuto sotto
///
/// Sezioni:
/// 1. Alert Rules — regole di notifica e alert critico
/// 2. Gateway Device — IP, tunnel, restart
/// 3. RFID & BLE — calibrazione sensori
/// 4. My Account — avatar, nome, password
/// 5. Appearance — tema dark/light (collegato a ThemeProvider), lingua (collegato a LocaleProvider)
/// 6. Data & Privacy — notifiche push, export, reset dati
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
  bool _notifEntry = true;
  bool _notifExit = true;
  bool _notifAlert = true;
  bool _notifForgotten = true;
  bool _notifUnauthorized = true;
  bool _notifQuietHours = false;
  bool _alertUnauthorized = true;
  bool _alertForgottenEssentials = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;

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
      _SettingsSection.alertRules => _AlertRulesContent(
          alertUnauthorized: _alertUnauthorized,
          onAlertUnauthorized: (v) =>
              setState(() => _alertUnauthorized = v),
          alertForgotten: _alertForgottenEssentials,
          onAlertForgotten: (v) =>
              setState(() => _alertForgottenEssentials = v),
          quietHours: _notifQuietHours,
          onQuietHours: (v) => setState(() => _notifQuietHours = v),
        ),
      _SettingsSection.gatewayDevice => _GatewayDeviceContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      _SettingsSection.rfidBle => _RfidBleContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      _SettingsSection.myAccount => _MyAccountContent(
          onAction: (msg) => _todoSnack(context, msg),
        ),
      // Appearance: passa i provider direttamente al widget
      // In questo modo _AppearanceContent può leggere e modificare
      // tema e lingua senza dipendere dal BuildContext genitore.
      _SettingsSection.appearance => _AppearanceContent(
          themeProvider: context.read<ThemeProvider>(),
          localeProvider: context.read<LocaleProvider>(),
        ),
      _SettingsSection.dataPrivacy => _DataPrivacyContent(
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
                Text(
                  activeSection.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
// Layout mobile: chip navigazione + contenuto
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
// Sub-nav item (desktop)
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
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
        const Text(
          'Configure when GateKeeper should send notifications or trigger critical alerts.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              _AlertRuleRow(
                title: 'Unauthorized Exit Alerts',
                subtitle:
                    'Trigger a CRITICAL alert if an object passes the gateway without an authenticated user (BLE) nearby.',
                value: alertUnauthorized,
                onChanged: onAlertUnauthorized,
              ),
              const Divider(color: AppColors.border),
              _AlertRuleRow(
                title: 'Forgotten Essential Items',
                subtitle:
                    'Notify the user if they leave without objects tagged as "Essentials" (e.g., Keys, Wallet).',
                value: alertForgotten,
                onChanged: onAlertForgotten,
              ),
              const Divider(color: AppColors.border),
              _AlertRuleRow(
                title: 'Quiet Hours',
                subtitle:
                    'Mute all non-critical notifications during specific hours.',
                value: quietHours,
                onChanged: onQuietHours,
              ),
              if (quietHours)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                  child: Row(
                    children: [
                      // TODO: implementare TimePickerDialog per selezionare l'ora
                      const _TimeChip(label: '10:00 PM'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ),
                      const _TimeChip(label: '07:00 AM'),
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
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.stormyTeal.withValues(alpha: 0.4),
            activeColor: AppColors.stormyTealBright,
          ),
        ],
      ),
    );
  }
}

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
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
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

/// Sezione Gateway Device: stato Raspberry Pi, IP, Cloudflare Tunnel, restart.
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
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsTile(
                label: 'Gateway IP / Hostname',
                subtitle: '192.168.1.150',
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
                    child: Icon(Icons.router_outlined,
                        color: AppColors.stormyTealBright, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Main Entry Gateway',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('IP: 192.168.1.150 · Uptime: 45 days',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
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

/// Sezione RFID & BLE: stato reader, calibrazione range BLE, intervallo RFID.
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
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

/// Sezione My Account: avatar, nome, email, cambio password, sessioni, 2FA.
class _MyAccountContent extends StatelessWidget {
  const _MyAccountContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.orange.withValues(alpha: 0.2),
                child: const Text('A',
                    style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alice Rossi',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text('alice@home.local · Admin',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => onAction('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.stormyTealBright,
                  side:
                      const BorderSide(color: AppColors.stormyTeal),
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
// 5. Appearance — CONNESSA AI PROVIDER REALI
// ---------------------------------------------------------------------------

/// Sezione Appearance: toggle dark/light theme e selezione lingua.
///
/// Questa sezione è l'unica che modifica direttamente i provider globali
/// dell'app. Le altre sezioni usano stato locale + snackBar stub.
///
/// Come funziona il tema:
/// - [ThemeProvider.toggle()] alterna dark ↔ light
/// - [MaterialApp.router] in app.dart ascolta [ThemeProvider.isDark]
///   e passa il ThemeMode corretto a Flutter — l'intera app si ridisegna
///
/// Come funziona la lingua:
/// - [LocaleProvider.setLocale()] cambia la locale dell'app
/// - [MaterialApp.router] in app.dart ascolta [LocaleProvider.locale]
///   e aggiorna il [Localizations] — i widget localizzati si adattano
///
/// NOTA: i colori del brand (teal, orange) NON cambiano tra i temi;
/// cambia solo lo sfondo e il testo (dark surfaces ↔ light surfaces).
/// Vedi [AppColors] vs [AppColorsLight] in app_colors.dart.
///
/// TODO: persistere la scelta tema/lingua con SharedPreferences.
///
/// Parametri:
/// - [themeProvider]: il provider del tema, iniettato dal parent
/// - [localeProvider]: il provider della lingua, iniettato dal parent
class _AppearanceContent extends StatelessWidget {
  const _AppearanceContent({
    required this.themeProvider,
    required this.localeProvider,
  });

  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo i provider qui per ricostruire quando cambiano.
    // context.watch fa sì che il widget si ridisegni quando il provider notifica.
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customize the look and language of GateKeeper.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // ── Card tema ─────────────────────────────────────────────────────
        const Text('THEME', style: AppTextStyles.label),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle dark / light — connesso a ThemeProvider
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.stormyTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      // Icona dinamica: luna = dark, sole = light
                      theme.isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: AppColors.stormyTealBright,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Theme',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(
                          // Label dinamica: mostra il tema attuale
                          theme.isDark ? 'Dark mode' : 'Light mode',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Switch collegato a ThemeProvider.toggle()
                  Switch.adaptive(
                    value: theme.isDark,
                    onChanged: (_) => theme.toggle(),
                    activeTrackColor:
                        AppColors.stormyTeal.withValues(alpha: 0.4),
                    activeColor: AppColors.stormyTealBright,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Anteprima visiva dei due temi (solo informativa)
              Row(
                children: [
                  _ThemePreviewChip(
                    label: 'Dark',
                    bgColor: const Color(0xFF0D1117),
                    textColor: const Color(0xFFF4F7FB),
                    isSelected: theme.isDark,
                    // Seleziona dark se non è già dark
                    onTap: () {
                      if (!theme.isDark) theme.toggle();
                    },
                  ),
                  const SizedBox(width: 10),
                  _ThemePreviewChip(
                    label: 'Light',
                    bgColor: const Color(0xFFF0E2E7),
                    textColor: const Color(0xFF0D1117),
                    isSelected: !theme.isDark,
                    // Seleziona light se non è già light
                    onTap: () {
                      if (theme.isDark) theme.toggle();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Card lingua ────────────────────────────────────────────────────
        const Text('LANGUAGE', style: AppTextStyles.label),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Italiano
              _LanguageOptionTile(
                flag: '🇮🇹',
                language: 'Italiano',
                subtitle: 'Italian',
                isSelected: locale.isItalian,
                onTap: () =>
                    locale.setLocale(const Locale('it')),
              ),
              const Divider(
                  color: AppColors.border, height: 1, indent: 56),
              // Inglese
              _LanguageOptionTile(
                flag: '🇬🇧',
                language: 'English',
                subtitle: 'English',
                isSelected: !locale.isItalian,
                onTap: () =>
                    locale.setLocale(const Locale('en')),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Info app ───────────────────────────────────────────────────────
        GlassCard(
          padding: EdgeInsets.zero,
          child: const SettingsTile(
            label: 'About GateKeeper',
            subtitle: 'v0.1.0-alpha — Smart tag, safe exit',
            icon: Icons.info_outline,
          ),
        ),
      ],
    );
  }
}

/// Chip anteprima tema (Dark / Light) con bordo di selezione teal.
///
/// Parametri:
/// - [label]: etichetta ('Dark' / 'Light')
/// - [bgColor]: colore di sfondo dell'anteprima
/// - [textColor]: colore del testo nell'anteprima
/// - [isSelected]: se è il tema attualmente attivo
/// - [onTap]: callback al tap
class _ThemePreviewChip extends StatelessWidget {
  const _ThemePreviewChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Bordo teal se selezionato, altrimenti bordo standard
            color:
                isSelected ? AppColors.stormyTealBright : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.phone_iphone,
                color: textColor.withValues(alpha: 0.6), size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle,
                  color: AppColors.stormyTealBright, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tile per la selezione della lingua con flag emoji e check di selezione.
///
/// Parametri:
/// - [flag]: emoji della bandiera
/// - [language]: nome della lingua nella lingua stessa
/// - [subtitle]: nome in inglese (per chiarezza)
/// - [isSelected]: se è la lingua attualmente attiva
/// - [onTap]: callback al tap → deve chiamare [LocaleProvider.setLocale]
class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.flag,
    required this.language,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String language;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Flag emoji in un cerchio
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.panelSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(flag,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(language,
                      style: TextStyle(
                          color: isSelected
                              ? AppColors.stormyTealBright
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400)),
                  const SizedBox(height: 2),
                  const Text('App language',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            // Check se selezionata
            if (isSelected)
              Icon(Icons.check_circle,
                  color: AppColors.stormyTealBright, size: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Data & Privacy
// ---------------------------------------------------------------------------

/// Sezione Data & Privacy + preferenze notifiche push.
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
                  activeTrackColor:
                      AppColors.stormyTeal.withValues(alpha: 0.4),
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Exit events',
                icon: Icons.logout_outlined,
                trailing: Switch.adaptive(
                  value: notifExit,
                  onChanged: onNotifExit,
                  activeTrackColor:
                      AppColors.stormyTeal.withValues(alpha: 0.4),
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
                  activeTrackColor:
                      AppColors.stormyTeal.withValues(alpha: 0.4),
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Forgotten items',
                icon: Icons.inventory_2_outlined,
                trailing: Switch.adaptive(
                  value: notifForgotten,
                  onChanged: onNotifForgotten,
                  activeTrackColor:
                      AppColors.stormyTeal.withValues(alpha: 0.4),
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
              SettingsTile(
                label: 'Unauthorized exits',
                icon: Icons.no_encryption_outlined,
                trailing: Switch.adaptive(
                  value: notifUnauthorized,
                  onChanged: onNotifUnauthorized,
                  activeTrackColor:
                      AppColors.stormyTeal.withValues(alpha: 0.4),
                  activeColor: AppColors.stormyTealBright,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
                onTap: () =>
                    onAction('Reset All Data — requires confirm'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
