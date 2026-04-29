import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptic_service.dart';
import '../../shared/widgets/gk_dialog.dart';
import '../../shared/widgets/gk_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Schermata profilo e gestione account dell'utente loggato.
///
/// Accessibile dalla sidebar desktop (icona avatar in basso)
/// o dal menu burger su mobile.
///
/// Sezioni:
/// - Avatar + nome + email (non modificabili via UI per ora);
/// - Modifica password;
/// - Impostazioni notifiche personali;
/// - Logout.
///
/// TODO: collegare le sezioni alle rispettive API:
/// - PATCH /api/users/me → modifica profilo
/// - POST /api/auth/change-password → cambio password
/// - DELETE /api/auth/logout → logout (invalida JWT)
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkBlack,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textSecondary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Account', style: AppTextStyles.cardTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profilo ───────────────────────────────────────────────
              _SectionHeader(title: 'Profile'),
              const SizedBox(height: 16),
              _ProfileCard(),
              const SizedBox(height: 28),

              // ── Sicurezza ─────────────────────────────────────────────
              _SectionHeader(title: 'Security'),
              const SizedBox(height: 16),
              _SecurityCard(),
              const SizedBox(height: 28),

              // ── Notifiche personali ───────────────────────────────────
              _SectionHeader(title: 'Personal Notifications'),
              const SizedBox(height: 16),
              _NotificationPrefsCard(),
              const SizedBox(height: 32),

              // ── Logout ────────────────────────────────────────────────
              _LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sotto-widget
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(fontSize: 11, letterSpacing: 1),
      );
}

/// Card con avatar, nome ed email dell'utente corrente.
///
/// TODO: rendere modificabile con EditProfileDialog
/// che chiama PATCH /api/users/me
class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar con iniziale
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.stormyTeal.withValues(alpha: 0.25),
            child: const Text(
              'A',
              style: TextStyle(
                color: AppColors.stormyTealBright,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alice (You)', style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                const Text('alice@home.local', style: AppTextStyles.body),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pulsante modifica
          // TODO: onPressed → EditProfileDialog
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card cambio password.
///
/// Apre un [GkDialog] con due campi: nuova password + conferma.
class _SecurityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.lock_outline,
          color: AppColors.textSecondary,
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        onTap: () => _showChangePasswordDialog(context),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    GkDialog.show(
      context: context,
      title: 'Change Password',
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GkTextField(
              label: 'New Password',
              hint: '••••••••',
              controller: newPassCtrl,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 14),
            GkTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: confirmCtrl,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  v != newPassCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    // TODO: await ApiService.changePassword(newPassCtrl.text)
                    await HapticService.success();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stormyTeal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Card con toggle per le notifiche personali dell'utente.
class _NotificationPrefsCard extends StatefulWidget {
  @override
  State<_NotificationPrefsCard> createState() =>
      _NotificationPrefsCardState();
}

class _NotificationPrefsCardState extends State<_NotificationPrefsCard> {
  // TODO: caricare e salvare le preferenze via GET+PATCH /api/users/me/notifications
  bool _exitAlerts = true;
  bool _entryAlerts = true;
  bool _childAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _PrefTile(
            label: 'Exit alerts',
            subtitle: 'When someone leaves the house',
            value: _exitAlerts,
            onChanged: (v) async {
              await HapticService.medium();
              setState(() => _exitAlerts = v);
            },
          ),
          Divider(height: 1, color: AppColors.border, indent: 16),
          _PrefTile(
            label: 'Entry alerts',
            subtitle: 'When someone arrives home',
            value: _entryAlerts,
            onChanged: (v) async {
              await HapticService.medium();
              setState(() => _entryAlerts = v);
            },
          ),
          Divider(height: 1, color: AppColors.border, indent: 16),
          _PrefTile(
            label: 'Child safety alerts',
            subtitle: 'Unsupervised exit, no phone nearby',
            value: _childAlerts,
            onChanged: (v) async {
              await HapticService.medium();
              setState(() => _childAlerts = v);
            },
          ),
        ],
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.stormyTealBright,
      inactiveTrackColor: AppColors.panelSoft,
    );
  }
}

/// Bottone logout con dialog di conferma.
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    GkDialog.show(
      context: context,
      title: 'Sign Out',
      child: const Text(
        'Are you sure you want to sign out?',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            await HapticService.heavy();
            // TODO: ApiService.logout() → invalida JWT sul backend
            if (context.mounted) {
              Navigator.of(context).pop(); // chiude dialog
              context.go('/login');        // torna al login
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
