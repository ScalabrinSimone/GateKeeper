import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Container che raggruppa un insieme di [SettingsTile] sotto un titolo.
///
/// Parametri:
/// - [title]: titolo della sezione
/// - [icon]: icona affiancata al titolo
/// - [children]: lista di widget (solitamente [SettingsTile])
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header sezione
        Row(
          children: [
            Icon(icon, color: AppColors.stormyTealBright, size: 16),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: AppTextStyles.label),
          ],
        ),
        const SizedBox(height: 10),

        // Card che contiene le voci
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...
                [
                  children[i],
                  if (i < children.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.border,
                      indent: 52,
                    ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
