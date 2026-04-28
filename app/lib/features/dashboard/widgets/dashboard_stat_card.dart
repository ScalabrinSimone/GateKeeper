import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 16),
          Text(value, style: AppTextStyles.metric),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: highlightColor ?? AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(icon, color: AppColors.textMuted),
        ],
      ),
    );
  }
}