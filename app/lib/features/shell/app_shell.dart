import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../theme/app_colors.dart';
import 'desktop_sidebar.dart';
import 'mobile_bottom_nav.dart';

/// Shell responsiva comune.
///
/// Questa è la "cornice" delle pagine:
/// - desktop: sidebar a sinistra
/// - mobile: bottom navigation
///
/// In questo modo ogni pagina si occupa solo del contenuto centrale.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.mobile;

        return Scaffold(
          backgroundColor: AppColors.inkBlack,
          bottomNavigationBar: isDesktop ? null : const MobileBottomNav(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF121826),
                  Color(0xFF0D1117),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                if (isDesktop) const DesktopSidebar(),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}