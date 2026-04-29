import 'package:flutter/material.dart';

/// Singola voce di navigazione della sidebar e della bottom bar.
///
/// Parametri:
/// - [label]: testo mostrato nella sidebar e nella bottom bar
/// - [icon]: icona Material (usa preferibilmente la variante _outlined)
/// - [route]: percorso go_router (es. '/dashboard')
class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Voci di navigazione principali dell'app.
///
/// ⚠️ NON includere 'Settings' qui: viene aggiunto separatamente
/// in fondo alla [DesktopSidebar] e nella [MobileBottomNav].
/// Aggiungerlo qui lo duplicherebbe.
const appNavigationItems = <NavigationItem>[
  NavigationItem(
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
  ),
  NavigationItem(
    label: 'Users & Roles',
    icon: Icons.group_outlined,
    route: '/users',
  ),
  NavigationItem(
    label: 'RFID Objects',
    icon: Icons.sell_outlined,
    route: '/objects',
  ),
  NavigationItem(
    label: 'Event Logs',
    icon: Icons.history_toggle_off_outlined,
    route: '/events',
  ),
  // NOTE: 'Settings' è intenzionalmente assente da questa lista.
  // Viene renderizzato come voce fissa in fondo alla sidebar desktop
  // e come ultimo item della bottom navigation mobile.
];
