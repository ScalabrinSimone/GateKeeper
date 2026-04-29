import 'package:flutter/material.dart';

import '../../../shared/widgets/gk_badge.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../objects_screen.dart';

/// Card di un oggetto RFID.
///
/// Mostra:
/// - icona oggetto;
/// - nome e categoria;
/// - badge stato (Home / Away / Unknown);
/// - ultima rilevazione;
/// - ID RFID in fondo.
///
/// Parametri:
/// - [object]: dato di tipo [RfidObject]
class ObjectCard extends StatelessWidget {
  const ObjectCard({super.key, required this.object});

  final RfidObject object;

  // Mappa stato → (label, colore)
  (String, Color) get _statusInfo => switch (object.status) {
        ObjectStatus.home => ('At Home', AppColors.success),
        ObjectStatus.away => ('Away', AppColors.orange),
        ObjectStatus.unknown => ('Unknown', AppColors.textMuted),
      };

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icona + badge stato
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.panelSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(object.icon,
                    color: AppColors.stormyTealBright, size: 22),
              ),
              const Spacer(),
              GkBadge(
                label: statusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nome
          Text(object.name, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),

          // Categoria
          Text(object.category, style: AppTextStyles.body),
          const SizedBox(height: 12),

          // Ultima rilevazione
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  object.lastSeen,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ID RFID
          Text(
            object.id,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
