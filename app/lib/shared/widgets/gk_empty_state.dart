import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Stato vuoto generico: icona + titolo + sottotitolo + bottone opzionale.
///
/// Da usare quando una lista/tabella non ha ancora contenuto.
///
/// Parametri:
/// - [icon]: icona centrale
/// - [title]: titolo principale
/// - [subtitle]: descrizione secondaria
/// - [actionLabel]: testo del CTA (opzionale)
/// - [onAction]: callback del CTA
class GkEmptyState extends StatelessWidget {
  const GkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cerchio con icona
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.panelSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.cardTitle),
            if (subtitle != null) ...
              [
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
            if (actionLabel != null && onAction != null) ...
              [
                const SizedBox(height: 24),
                // Bottone primario senza sfondo gradient (vedi anti-pattern)
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stormyTeal,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
