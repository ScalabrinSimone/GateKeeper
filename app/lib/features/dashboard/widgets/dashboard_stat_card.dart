import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Card statistica nella riga superiore della dashboard.
///
/// Occupa tutto lo spazio verticale disponibile tramite [IntrinsicHeight]
/// nel parent, e distribuisce il contenuto su tre aree:
/// - etichetta in alto
/// - valore grande al centro
/// - icona + subtitle in basso
///
/// Parametri:
/// - [label]: titolo piccolo uppercase (es. 'Gateway Status')
/// - [value]: numero o testo grande (es. 'Active', '3')
/// - [subtitle]: riga descrittiva sotto il valore
/// - [icon]: icona in basso a sinistra
/// - [highlightColor]: se fornito, colora subtitle e icona (verde, arancione...)
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.highlightColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final accent = highlightColor ?? AppColors.textSecondary;
    return GlassCard(
      // Padding generoso per riempire lo spazio
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Etichetta uppercase piccola
          Text(label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 14),
          // Valore principale (grande)
          Text(value,
              style: AppTextStyles.metric.copyWith(fontSize: 36)),
          const SizedBox(height: 8),
          // Subtitle colorata
          Text(
            subtitle,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Icona grande in basso
          Icon(icon, color: accent, size: 28),
        ],
      ),
    );
  }
}
