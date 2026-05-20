import 'package:flutter/material.dart';

class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}
