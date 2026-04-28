import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/haptics.dart';
import '../../shared/widgets/gatekeeper_logo.dart';
import '../../theme/app_colors.dart';
import 'navigation_item.dart';

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
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GateKeeperLogo(),
              const SizedBox(height: 28),
              ...appNavigationItems.map((item) {
                final isSelected = location.startsWith(item.route);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await AppHaptics.selection();
                      if (!context.mounted) return;
                      context.go(item.route);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.stormyTeal.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected
                                ? AppColors.stormyTealBright
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.stormyTealBright
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go('/settings'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                      SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}