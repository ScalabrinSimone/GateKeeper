import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Singola voce in una [SettingsSection].
///
/// Parametri:
/// - [label]: testo principale
/// - [subtitle]: testo secondario opzionale
/// - [icon]: icona a sinistra
/// - [trailing]: widget a destra opzionale (es. Switch, Badge)
/// - [onTap]: callback tap; se null la riga non è cliccabile
/// - [labelColor]: colore override del testo (es. rosso per Sign Out)
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    this.labelColor,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      // Bordi arrotondati per il feedback ripple
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icona a sinistra
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),

            // Testo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: labelColor ?? AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...
                    [
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.body),
                    ],
                ],
              ),
            ),

            // Trailing (Switch, Badge, ecc.) oppure chevron se è cliccabile
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
