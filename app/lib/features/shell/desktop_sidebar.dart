import 'package:flutter/material.dart';

import '../../shared/widgets/gatekeeper_logo.dart';
import '../../theme/app_colors.dart';

/// Sidebar desktop principale.
///
/// Sostituisce la precedente icona "scudo" con il logo ufficiale GateKeeper.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GateKeeperLogo(height: 40, compact: true),
          const SizedBox(height: 32),
          // TODO: qui sotto rimane il contenuto esistente di navigazione
        ],
      ),
    );
  }
}
