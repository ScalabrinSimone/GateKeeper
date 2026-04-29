import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../events_screen.dart';

/// Tile di un evento nel log.
///
/// Colore del bordo sinistro varia per tipo:
/// - Unauthorized → rosso;
/// - Alert        → arancione;
/// - Forgotten    → giallo;
/// - Entry        → verde;
/// - Exit         → teal.
///
/// Parametri:
/// - [event]: dato di tipo [GkEvent]
/// - [onTap]: callback per aprire il dettaglio (TODO Blocco 2B)
class EventListTile extends StatelessWidget {
  const EventListTile({
    super.key,
    required this.event,
    this.onTap,
  });

  final GkEvent event;
  final VoidCallback? onTap;

  // Colore per tipo evento
  Color get _color => switch (event.type) {
        EventType.unauthorized => const Color(0xFFFF4D4D),
        EventType.alert => AppColors.warning,
        EventType.forgotten => AppColors.orange,
        EventType.entry => AppColors.success,
        EventType.exit => AppColors.stormyTealBright,
      };

  // Icona per tipo evento
  IconData get _icon => switch (event.type) {
        EventType.unauthorized => Icons.no_encryption_outlined,
        EventType.alert => Icons.warning_amber_outlined,
        EventType.forgotten => Icons.inventory_2_outlined,
        EventType.entry => Icons.login_outlined,
        EventType.exit => Icons.logout_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra colorata a sinistra — NON è un colored side border
                // (vedi app_colors): qui è usata come indicatore di stato,
                // non come decorazione. Spessore 4px per coerenza.
                Container(width: 4, color: _color),

                // Contenuto
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Riga tipo + orario
                        Row(
                          children: [
                            Icon(_icon, color: _color, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.title,
                                style: AppTextStyles.cardTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              event.timestamp,
                              style: AppTextStyles.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Descrizione
                        Text(
                          event.description,
                          style: AppTextStyles.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Chips utente / oggetto
                        if (event.user != null || event.object != null) ...
                          [
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (event.user != null)
                                  _MiniChip(
                                    icon: Icons.person_outline,
                                    label: event.user!,
                                  ),
                                if (event.object != null)
                                  _MiniChip(
                                    icon: Icons.sell_outlined,
                                    label: event.object!,
                                  ),
                              ],
                            ),
                          ],
                      ],
                    ),
                  ),
                ),

                // Freccia caret se ha onTap
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Piccola chip con icona+testo per user e object nella tile.
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
