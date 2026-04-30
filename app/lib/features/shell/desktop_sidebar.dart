import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Sidebar principale per layout desktop.
///
/// Evidenzia la voce attiva in base alla location corrente
/// usando [GoRouterState.location]. Questo evita di mantenere
/// uno stato manuale ed è resiliente alla navigazione programmatica.
///
/// TODO: collegare il badge Alert alla pagina Event Logs con filtro alert.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
        color: AppColors.sidebarBg,
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            // Rotte principali definite in app_router.dart
            route: '/dashboard',
            isActive: location.startsWith('/dashboard'),
          ),
          _NavItem(
            icon: Icons.group_outlined,
            label: 'Users & Roles',
            route: '/users',
            isActive: location.startsWith('/users'),
          ),
          _NavItem(
            icon: Icons.key_outlined,
            label: 'RFID Objects',
            route: '/objects',
            isActive: location.startsWith('/objects'),
          ),
          _NavItem(
            icon: Icons.list_alt_outlined,
            label: 'Event Logs',
            route: '/events',
            isActive: location.startsWith('/events'),
          ),
          const Spacer(),
          const Divider(color: AppColors.border, height: 1),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            route: '/settings',
            isActive: location.startsWith('/settings'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.stormyTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vpn_key,
                color: AppColors.stormyTealBright, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('GateKeeper', style: AppTextStyles.sidebarTitle),
        ],
      ),
    );
  }
}

/// Singola voce di navigazione nella sidebar desktop.
///
/// Parametri:
/// - [icon]: icona principale
/// - [label]: testo
/// - [route]: path go_router
/// - [isActive]: se la voce è correntemente selezionata
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Naviga solo se non siamo già sulla stessa route per evitare
        // di ricostruire inutilmente lo stack.
        if (!isActive) context.go(route);
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.sidebarActiveBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.stormyTealBright
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
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
