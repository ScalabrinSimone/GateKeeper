import 'package:flutter/material.dart';
import 'dart:ui';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../events_screen.dart';

/// Bottom sheet con i dettagli di un singolo evento gateway.
///
/// Aperto con [EventDetailSheet.show] dallo swipe su una tile
/// o dal tap sul tasto info della tile.
///
/// Mostra:
/// - tipo evento + timestamp formattato;
/// - utente associato (se presente);
/// - oggetti coinvolti (lista con icone);
/// - direzione (IN/OUT);
/// - nota alert se l'evento ha generato una notifica.
///
/// TODO: aggiungere bottone "Dismiss Alert" che chiama
/// PATCH /api/events/{id}/dismiss e aggiorna la lista.
///
/// Utilizzo:
/// ```dart
/// EventDetailSheet.show(context, event: myEvent);
/// ```
class EventDetailSheet {
  /// Mostra il bottom sheet modale con backdrop blur.
  static void show(BuildContext context, {required GkEvent event}) {
    showModalBottomSheet<void>(
      context: context,
      // backgroundColor trasparente: usiamo un Container custom
      backgroundColor: Colors.transparent,
      // isScrollControlled: permette al sheet di occupare più del 50%
      isScrollControlled: true,
      builder: (_) => _EventDetailContent(event: event),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenuto del sheet
// ---------------------------------------------------------------------------

class _EventDetailContent extends StatelessWidget {
  const _EventDetailContent({required this.event});

  final GkEvent event;

  @override
  Widget build(BuildContext context) {
    // Colore dell'evento basato sul tipo
    final typeColor = _typeColor(event.type);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.border),
            left: BorderSide(color: AppColors.border),
            right: BorderSide(color: AppColors.border),
          ),
        ),
        // SafeArea bottom per iPhone con notch
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: tipo evento + timestamp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Icona colorata per il tipo evento
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _typeIcon(event.type),
                        color: typeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _typeLabel(event.type),
                            style: AppTextStyles.cardTitle,
                          ),
                          Text(
                            // Formato: "Wed, 29 Apr 2026 — 10:24"
                            _formatDateTime(event.timestamp),
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              // Dettagli
              _DetailSection(
                icon: Icons.person_outline,
                label: 'User',
                value: event.userName ?? 'Unknown',
              ),
              _DetailSection(
                icon: event.direction == EventDirection.out
                    ? Icons.logout
                    : Icons.login,
                label: 'Direction',
                value: event.direction == EventDirection.out ? 'OUT' : 'IN',
                valueColor: event.direction == EventDirection.out
                    ? AppColors.warning
                    : AppColors.success,
              ),

              if (event.objectNames.isNotEmpty)
                _ObjectsList(objects: event.objectNames),

              // Alert se l'evento ha generato una notifica
              if (event.alertMessage != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.alertMessage!,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // TODO: bottone Dismiss Alert
              // if (event.alertMessage != null)
              //   Padding(
              //     padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
              //     child: _DismissButton(eventId: event.id),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _typeColor(EventType type) => switch (type) {
        EventType.exit => AppColors.warning,
        EventType.entry => AppColors.success,
        EventType.alert => Colors.redAccent,
        EventType.scan => AppColors.stormyTealBright,
      };

  IconData _typeIcon(EventType type) => switch (type) {
        EventType.exit => Icons.logout,
        EventType.entry => Icons.login,
        EventType.alert => Icons.warning_amber_outlined,
        EventType.scan => Icons.nfc_outlined,
      };

  String _typeLabel(EventType type) => switch (type) {
        EventType.exit => 'Exit Event',
        EventType.entry => 'Entry Event',
        EventType.alert => 'Alert Triggered',
        EventType.scan => 'RFID Scan',
      };

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = days[dt.weekday - 1];
    final m = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d, ${dt.day} $m ${dt.year} — $h:$min';
  }
}

// ---------------------------------------------------------------------------
// Sotto-widget di dettaglio
// ---------------------------------------------------------------------------

/// Riga singola label + valore nel bottom sheet.
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.body),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista oggetti RFID coinvolti nell'evento.
class _ObjectsList extends StatelessWidget {
  const _ObjectsList({required this.objects});

  final List<String> objects;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nfc_outlined,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text('Objects', style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 8),
          ...objects.map(
            (obj) => Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.stormyTealBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    obj,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
