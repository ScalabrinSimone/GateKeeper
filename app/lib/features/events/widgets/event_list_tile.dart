import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../events_screen.dart';

/// Tile di un evento nel log mobile.
///
/// Il bordo sinistro colorato è usato come **indicatore semantico di stato**
/// (non come decorazione), coerentemente con le linee guida AppColors.
///
/// Parametri:
/// - [event]: dato di tipo [GkEvent] (definito in events_screen.dart)
/// - [onTap]: callback per aprire il dettaglio sheet
class EventListTile extends StatelessWidget {
  const EventListTile({
    super.key,
    required this.event,
    this.onTap,
  });

  final GkEvent event;
  final VoidCallback? onTap;

  /// Colore dell'indicatore laterale in base al tipo di evento.
  Color get _color => switch (event.type) {
        EventType.alert => AppColors.warning,
        EventType.entry => AppColors.success,
        EventType.exit  => AppColors.stormyTealBright,
        EventType.scan  => AppColors.textMuted,
      };

  /// Icona in base al tipo di evento.
  IconData get _icon => switch (event.type) {
        EventType.alert => Icons.warning_amber_outlined,
        EventType.entry => Icons.login_outlined,
        EventType.exit  => Icons.logout_outlined,
        EventType.scan  => Icons.wifi_tethering_outlined,
      };

  /// Titolo leggibile derivato dal tipo di evento.
  String get _title => switch (event.type) {
        EventType.alert => 'Alert',
        EventType.entry => 'Entry',
        EventType.exit  => 'Exit',
        EventType.scan  => 'RFID Scan',
      };

  /// Descrizione derivata dai campi del modello.
  String get _description {
    if (event.alertMessage != null) return event.alertMessage!;
    final user = event.userName ?? 'Unknown user';
    final objs = event.objectNames.isEmpty
        ? 'no objects detected'
        : event.objectNames.join(', ');
    return '$user — $objs';
  }

  /// Formatta il [DateTime] in "HH:MM AM/PM".
  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

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
                // Barra colorata a sinistra — indicatore di stato semantico.
                Container(width: 4, color: _color),

                // Contenuto principale
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Riga: icona tipo + titolo + orario
                        Row(
                          children: [
                            Icon(_icon, color: _color, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _title,
                                style: AppTextStyles.cardTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTime(event.timestamp),
                              style: AppTextStyles.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Descrizione evento
                        Text(
                          _description,
                          style: AppTextStyles.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Chips utente + oggetti
                        if (event.userName != null ||
                            event.objectNames.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (event.userName != null)
                                _MiniChip(
                                  icon: Icons.person_outline,
                                  label: event.userName!,
                                ),
                              for (final obj in event.objectNames)
                                _MiniChip(
                                  icon: Icons.sell_outlined,
                                  label: obj,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Freccia caret se ha callback
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

/// Chip compatta per mostrare utente o oggetto associato all'evento.
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}