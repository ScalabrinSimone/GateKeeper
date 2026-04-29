import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptic_service.dart';
import '../../theme/app_colors.dart';

/// Barra azioni in alto a destra: notifiche + profilo utente con menu rapido.
///
/// Il bottone con il nome utente apre un [PopupMenuButton] con:
/// - My Account → /account
/// - Notification Settings (stub)
/// - Sign Out → dialog conferma → /login
///
/// TODO: collegare al provider utente reale per mostrare nome dinamico.
/// TODO: badge notifiche da stream backend.
class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Badge Alerts ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            color: AppColors.panelSoft,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none,
                  size: 18, color: AppColors.textPrimary),
              SizedBox(width: 6),
              Text(
                'Alerts (2)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // --- Profilo utente con dropdown ---
        _UserMenuButton(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dropdown menu utente
// ---------------------------------------------------------------------------

/// Bottone avatar+nome che apre un menu a tendina con le azioni rapide.
///
/// Voci del menu:
/// - My Account: naviga a /account
/// - Notification Settings: stub (TODO)
/// - Sign Out: dialog di conferma, poi go('/login')
class _UserMenuButton extends StatelessWidget {
  // Valori degli item del popup
  static const _itemAccount = 'account';
  static const _itemNotifications = 'notifications';
  static const _itemSignOut = 'signout';

  Future<void> _handleSignOut(BuildContext context) async {
    // Chiede conferma prima di disconnettersi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Feedback aptico pesante per azione distruttiva
      await HapticService.heavy();
      // TODO: cancellare JWT da AuthState quando il backend sarà pronto
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      // Posiziona il menu sotto il bottone
      offset: const Offset(0, 42),
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case _itemAccount:
            await HapticService.light();
            if (context.mounted) context.push('/account');
          case _itemNotifications:
            // TODO: aprire pannello notifiche o navigare a /settings
            await HapticService.light();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification settings — coming soon')),
              );
            }
          case _itemSignOut:
            await _handleSignOut(context);
        }
      },
      // Il bottone che fa da trigger del menu
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.panelSoft,
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.orange,
              child: Icon(Icons.person, size: 14, color: AppColors.inkBlack),
            ),
            SizedBox(width: 6),
            Text(
              'Alice',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
      // Voci del menu
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: _itemAccount,
          child: Row(
            children: const [
              Icon(Icons.person_outline, size: 17, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('My Account',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: _itemNotifications,
          child: Row(
            children: const [
              Icon(Icons.notifications_none, size: 17, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Text('Notification Settings',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),
        // Separatore visivo prima di Sign Out
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _itemSignOut,
          child: Row(
            children: const [
              Icon(Icons.logout, size: 17, color: AppColors.error),
              SizedBox(width: 10),
              Text('Sign Out',
                  style: TextStyle(color: AppColors.error, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
