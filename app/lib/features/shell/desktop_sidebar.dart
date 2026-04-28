import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/haptics.dart';
import '../../shared/widgets/gatekeeper_logo.dart';
import '../../theme/app_colors.dart';
import 'navigation_item.dart';

/// Sidebar desktop con:
/// - logo GateKeeper in cima
/// - voci di navigazione animate (shift a destra su selezione)
/// - Settings in fondo (unico, non duplicato)
///
/// L'animazione su selezione usa [AnimatedPadding] per spostare
/// leggermente icona+testo a destra quando la voce è attiva.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GateKeeperLogo(),
              const SizedBox(height: 28),

              // Voci di navigazione principali
              ...appNavigationItems.map((item) {
                final isSelected = location.startsWith(item.route);
                return _NavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () async {
                    await AppHaptics.selection();
                    if (!context.mounted) return;
                    context.go(item.route);
                  },
                );
              }),

              const Spacer(),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),

              // Settings in fondo — NON duplicare nelle voci sopra
              _NavItem(
                item: NavigationItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  route: '/settings',
                ),
                isSelected: location.startsWith('/settings'),
                onTap: () async {
                  await AppHaptics.selection();
                  if (!context.mounted) return;
                  context.go('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Singola voce della sidebar con animazione di shift a destra.
///
/// Quando [isSelected] diventa true:
/// - il padding sinistro si riduce (effetto shift a destra)
/// - sfondo teal semi-trasparente appare
/// - colore testo/icona diventa [AppColors.stormyTealBright]
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          // Shift a destra: il padding sinistro si riduce quando selezionato
          padding: EdgeInsets.only(
            left: isSelected ? 18 : 12,
            right: 12,
            top: 13,
            bottom: 13,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.stormyTeal.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            // Row non deve overflow: usa MainAxisSize.min
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected
                    ? AppColors.stormyTealBright
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.stormyTealBright
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
