import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';

/// Card singola nell'activity feed.
///
/// Parametri:
/// - [title]: titolo evento (es. 'UNAUTHORIZED EXIT')
/// - [description]: descrizione breve
/// - [time]: orario stringa (es. '10:45 AM')
/// - [objectName]: nome oggetto RFID coinvolto
/// - [objectIcon]: icona placeholder per l'oggetto (laptop, portafoglio, chiavi...)
/// - [tags]: lista di tag (categorie, posizioni...)
/// - [icon]: icona del tipo evento
/// - [borderColor]: colore del bordo sinistro (identifica severità)
/// - [cardBackground]: sfondo opzionale del riquadro interno
/// - [actionLabel]: se presente, mostra un pulsante CTA in basso a destra
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.objectName,
    required this.objectIcon,
    required this.tags,
    required this.icon,
    required this.borderColor,
    this.cardBackground,
    this.actionLabel,
  });

  final String title;
  final String description;
  final String time;
  final String objectName;
  final IconData objectIcon;
  final List<String> tags;
  final IconData icon;
  final Color borderColor;
  final Color? cardBackground;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: borderColor,
      // Sfondo personalizzabile: più chiaro per eventi neutri
      color: cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Riga titolo + orario ---
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: borderColor.withValues(alpha: 0.14),
                child: Icon(icon, color: borderColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // --- Descrizione ---
          Text(
            description,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // --- Riquadro oggetto RFID ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.panelSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(objectIcon,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      objectName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tag wrap (gestisce overflow automaticamente)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.deepNavy,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Pulsante CTA (solo per eventi con azione richiesta)
                if (actionLabel != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.inkBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        // TODO: collegare a logica backend (mark event as false alarm)
                      },
                      child: Text(actionLabel!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
