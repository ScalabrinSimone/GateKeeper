import 'package:flutter/material.dart';

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
  NavigationItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  ),
];