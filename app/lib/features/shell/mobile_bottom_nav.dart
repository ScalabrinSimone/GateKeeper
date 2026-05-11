import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/haptics.dart';
import '../../theme/app_colors.dart';
import 'navigation_item.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  int _locationToIndex(String location) {
    final index = appNavigationItems.indexWhere(
      (item) => location.startsWith(item.route),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: NavigationBar(
        height: 72,
        backgroundColor: AppColors.deepNavy,
        indicatorColor: AppColors.stormyTeal.withValues(alpha: 0.18),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) async {
          await AppHaptics.selection();
          if (!context.mounted) return;
          context.go(appNavigationItems[index].route);
        },
        destinations: appNavigationItems.take(4).map((item) {
          return NavigationDestination(
            icon: Icon(item.icon, color: AppColors.textSecondary),
            selectedIcon: Icon(item.icon, color: AppColors.stormyTealBright),
            label: item.label.split(' ').first,
          );
        }).toList(),
      ),
    );
  }
}