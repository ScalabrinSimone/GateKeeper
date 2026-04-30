import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Sidebar principale per layout desktop.
///
/// # Correzione bug dark/light mode
/// Tutti i colori hardcoded ([AppColors.sidebarBg], [AppColors.border],
/// [AppColors.textSecondary], [AppColors.sidebarActiveBg]) sono stati
/// sostituiti con valori derivati da `Theme.of(context).colorScheme`.
/// In questo modo dark e light mode funzionano correttamente su tutta la sidebar.
///
/// - Dark mode: usa i colori brand originali del mockup (#111827, border, teal)
/// - Light mode: usa `colorScheme.surfaceContainerLow`, `outlineVariant`,
///   `primary`, `onSurfaceVariant` per un aspetto pulito e coerente con Material 3.
///
/// L'evidenziazione della voce attiva usa la location corrente di go_router
/// per evitare di mantenere stato manuale.
///
/// TODO: collegare il badge Alerts alla pagina Event Logs con filtro alert.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sfondo sidebar: brand dark in dark mode, surfaceContainerLow in light mode.
    // surfaceContainerLow è leggermente più scuro di surface, crea separazione visiva.
    final sidebarBg = isDark ? AppColors.sidebarBg : colorScheme.surfaceContainerLow;

    // Bordo destro: brand border in dark, outlineVariant in light (sottile, armonioso)
    final borderColor = isDark ? AppColors.border : colorScheme.outlineVariant;

    return Container(
      width: 220,
      // PRIMA (bug): const BoxDecoration(color: AppColors.sidebarBg) → sempre scuro
      // ORA (fix):   colore dinamico basato sul tema corrente
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor),
        ),
        color: sidebarBg,
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            // Rotte definite in app_router.dart
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
          Divider(color: borderColor, height: 1),
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

/// Header della sidebar con logo e nome app.
///
/// Usa `Theme.of(context)` per adattare il colore del testo al tema corrente.
/// Il logo usa [Image.asset] con fallback all'icona se l'asset non è disponibile.
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          // Contenitore logo con sfondo semi-trasparente teal.
          // Image.asset carica gatekeeper_logo.png dagli assets del progetto;
          // errorBuilder garantisce che la sidebar sia sempre funzionante
          // anche se l'asset non è ancora stato copiato/sincronizzato.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.stormyTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/gatekeeper_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                // Fallback: se l'asset non è disponibile mostra l'icona brand
                errorBuilder: (_, __, ___) => Icon(
                  Icons.vpn_key,
                  color: AppColors.stormyTealBright,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'GateKeeper',
            style: AppTextStyles.sidebarTitle.copyWith(
              // In light mode il testo deve essere scuro per contrasto
              color: isDark ? null : AppColors.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}

/// Singola voce di navigazione nella sidebar desktop.
///
/// I colori di testo, icona e sfondo si adattano automaticamente a dark/light
/// usando `Theme.of(context).colorScheme` invece di [AppColors] hardcoded.
///
/// Parametri:
/// - [icon]: icona Material principale
/// - [label]: testo della voce
/// - [route]: path go_router per la navigazione
/// - [isActive]: true se la voce corrisponde alla route corrente
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colori voce attiva: teal brillante in dark, primary del tema in light
    final activeColor =
        isDark ? AppColors.stormyTealBright : colorScheme.primary;

    // Colori voce inattiva: grigio muted in dark, onSurfaceVariant in light
    final inactiveColor =
        isDark ? AppColors.textSecondary : colorScheme.onSurfaceVariant;

    // Sfondo voce attiva: panel leggermente più chiaro in dark,
    // primaryContainer semi-trasparente in light
    final activeBg = isDark
        ? AppColors.sidebarActiveBg
        : colorScheme.primaryContainer.withValues(alpha: 0.35);

    return InkWell(
      onTap: () {
        // Naviga solo se non siamo già sulla stessa route per evitare
        // ricostruzioni inutili dello stack.
        if (!isActive) context.go(route);
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // PRIMA (bug): AppColors.sidebarActiveBg hardcoded → stesso in dark/light
          // ORA (fix):   activeBg dipende dal tema corrente
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              // PRIMA (bug): AppColors.stormyTealBright / textSecondary hardcoded
              // ORA (fix):   activeColor / inactiveColor dipendono dal tema
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
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
