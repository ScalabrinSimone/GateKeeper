import 'package:flutter/material.dart';

import '../../shared/widgets/gatekeeper_logo.dart';
import '../../theme/app_colors.dart';
import 'navigation_item.dart';

/// Sidebar desktop principale.
///
/// Contiene:
/// - Logo GateKeeper in alto
/// - Voci di navigazione principali (Overview, Users, RFID, Event Logs)
/// - Voce Settings fissata in fondo
///
/// NOTA: la logica di navigazione (route) è centralizzata in
/// [appNavigationItems] e in [AppRouter]. Questa sidebar si occupa solo
/// della parte visuale; il click navigation è gestito dentro
/// [_DesktopNavItems] tramite go_router.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo brand in alto
          GateKeeperLogo(height: 40, compact: true),
          SizedBox(height: 32),
          // Contenuto esistente di navigazione ripristinato sotto il logo
          _DesktopNavItems(),
        ],
      ),
    );
  }
}

/// Lista voci di navigazione della sidebar desktop.
///
/// Usa [NavigationItem] per etichette/icone/route in modo coerente
/// con la bottom nav mobile.
class _DesktopNavItems extends StatelessWidget {
  const _DesktopNavItems();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voci principali
          for (final item in appNavigationItems) ...[
            _SidebarItem(item: item),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          const _SettingsItem(),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item});

  final NavigationItem item;

  @override
  Widget build(BuildContext context) {
    final router = GoRouterState.of(context);
    final isActive = router.uri.toString().startsWith(item.route);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go(item.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.stormyTeal.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive
                  ? AppColors.stormyTealBright
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                color: isActive
                    ? AppColors.stormyTealBright
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem();

  @override
  Widget build(BuildContext context) {
    final router = GoRouterState.of(context);
    final isActive = router.uri.toString().startsWith('/settings');

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go('/settings'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.stormyTeal.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.settings_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 10),
            Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
