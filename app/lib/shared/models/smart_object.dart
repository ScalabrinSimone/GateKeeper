import 'package:flutter/material.dart';

import 'enums.dart';

//Oggetto smart taggato via RFID.
//Mappabile su devices del backend (rfid_tag, category, is_essential, alert_rules, current_status).
class SmartObject {
  const SmartObject({
    required this.id,
    required this.name,
    required this.rfidTag,
    required this.category,
    required this.isInside,
    this.ownerId,
    this.isEssential = false,
    this.lastMovementAt,
    this.iconOverride,
  });

  final String id;
  final String name;
  final String rfidTag;
  final ObjectCategory category;
  final bool isInside;
  final String? ownerId;
  final bool isEssential;
  final DateTime? lastMovementAt;
  final IconData? iconOverride;

  //Icona predefinita per categoria.
  IconData get icon {
    if (iconOverride != null) return iconOverride!;
    switch (category) {
      case ObjectCategory.keys:
        return Icons.vpn_key_rounded;
      case ObjectCategory.wallet:
        return Icons.account_balance_wallet_rounded;
      case ObjectCategory.umbrella:
        return Icons.umbrella_rounded;
      case ObjectCategory.bag:
        return Icons.work_rounded;
      case ObjectCategory.phone:
        return Icons.smartphone_rounded;
      case ObjectCategory.other:
        return Icons.inventory_2_rounded;
    }
  }
}
