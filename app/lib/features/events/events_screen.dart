import 'package:flutter/material.dart';

import '../../core/services/haptic_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/event_detail_sheet.dart';

// ---------------------------------------------------------------------------
// Modelli
// ---------------------------------------------------------------------------

/// Direzione dell'evento: uscita o entrata dalla porta.
enum EventDirection { out, in_ }

/// Tipo di evento generato dal sistema GateKeeper.
///
/// - [exit]: oggetto/utente rilevati in uscita
/// - [entry]: oggetto/utente rilevati in entrata
/// - [alert]: evento anomalo (bambino senza telefono, oggetto sensibile fuori, ecc.)
/// - [scan]: scansione RFID generica senza movimento porta
enum EventType { exit, entry, alert, scan }

/// Singolo evento registrato dal gateway.
///
/// Parametri:
/// - [id]: identificatore univoco
/// - [type]: [EventType]
/// - [direction]: [EventDirection]
/// - [timestamp]: data/ora dell'evento
/// - [userName]: nome dell'utente associato (null se non identificato)
/// - [objectNames]: oggetti RFID rilevati durante l'evento
/// - [alertMessage]: testo notifica se l'evento ha generato un alert
class GkEvent {
  const GkEvent({
    required this.id,
    required this.type,
    required this.direction,
    required this.timestamp,
    this.userName,
    this.objectNames = const [],
    this.alertMessage,
  });

  final String id;
  final EventType type;
  final EventDirection direction;
  final DateTime timestamp;
  final String? userName;
  final List<String> objectNames;
  final String? alertMessage;
}

// ---------------------------------------------------------------------------
// Dati stub
// ---------------------------------------------------------------------------

/// TODO: rimpiazzare con GET /api/events (paginato) dal backend.
final _stubEvents = [
  GkEvent(
    id: 'e1',
    type: EventType.exit,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    userName: 'Alice',
    objectNames: ['House Keys', 'Laptop Bag'],
  ),
  GkEvent(
    id: 'e2',
    type: EventType.alert,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
    userName: 'Charlie',
    objectNames: [],
    alertMessage: 'Child exited without phone detected nearby.',
  ),
  GkEvent(
    id: 'e3',
    type: EventType.entry,
    direction: EventDirection.in_,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    userName: 'Bob',
    objectNames: ['Umbrella'],
  ),
  GkEvent(
    id: 'e4',
    type: EventType.exit,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    userName: 'Alice',
    objectNames: ['House Keys'],
  ),
  GkEvent(
    id: 'e5',
    type: EventType.scan,
    direction: EventDirection.in_,
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    userName: null,
    objectNames: ['Unknown Tag #A4F2'],
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata storico eventi gateway.
///
/// Mostra una lista cronologica degli eventi RFID/BLE.
/// Ogni tile è tappabile: apre [EventDetailSheet] con i dettagli.
///
/// I filtri (All / Exits / Entries / Alerts) usano [AnimatedContainer]
/// per l'animazione del chip selezionato.
///
/// TODO: paginazione infinita con scroll listener.
/// TODO: filtro per data con DateRangePicker.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // null = tutti i tipi
  EventType? _activeFilter;

  // Filtri disponibili: null = "All"
  static const _filters = <(EventType?, String)>[
    (null, 'All'),
    (EventType.exit, 'Exits'),
    (EventType.entry, 'Entries'),
    (EventType.alert, 'Alerts'),
    (EventType.scan, 'Scans'),
  ];

  List<GkEvent> get _filteredEvents => _activeFilter == null
      ? _stubEvents
      : _stubEvents.where((e) => e.type == _activeFilter).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(title: 'Event Logs'),

          // Filtri chip animati
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final (type, label) = f;
                  final active = _activeFilter == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () async {
                        await HapticService.light();
                        setState(() => _activeFilter = type);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // Il chip attivo diventa teal, gli altri restano scuri
                          color: active
                              ? AppColors.stormyTeal
                              : AppColors.panelSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppColors.stormyTeal
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: active
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista eventi
          Expanded(
            child: _filteredEvents.isEmpty
                ? const _EmptyEvents()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, i) {
                      return _EventTile(
                        event: _filteredEvents[i],
                        onTap: () => EventDetailSheet.show(
                          context,
                          event: _filteredEvents[i],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile evento
// ---------------------------------------------------------------------------

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onTap});

  final GkEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(event.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.panelSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Barra colorata sinistra che indica il tipo di evento
            Container(
              width: 4,
              height: 64,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Icona tipo
            Icon(_typeIcon(event.type), color: typeColor, size: 20),
            const SizedBox(width: 12),

            // Nome utente + oggetti
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.userName ?? 'Unknown user',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                  ),
                  if (event.objectNames.isNotEmpty)
                    Text(
                      event.objectNames.join(', '),
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (event.alertMessage != null)
                    Text(
                      event.alertMessage!,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Timestamp + freccia info
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(event.timestamp),
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Restituisce il colore associato al tipo di evento.
  /// Usa sempre le costanti di [AppColors] — mai valori Material hardcoded.
  Color _typeColor(EventType type) => switch (type) {
        EventType.exit  => AppColors.warning,
        EventType.entry => AppColors.success,
        // FIX: era Colors.redAccent — ora usa AppColors.error dalla palette
        EventType.alert => AppColors.error,
        EventType.scan  => AppColors.stormyTealBright,
      };

  IconData _typeIcon(EventType type) => switch (type) {
        EventType.exit  => Icons.logout,
        EventType.entry => Icons.login,
        EventType.alert => Icons.warning_amber_outlined,
        EventType.scan  => Icons.nfc_outlined,
      };

  /// Calcola il tempo relativo (es. "5m ago", "2h ago").
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_outlined, color: AppColors.textMuted, size: 48),
          SizedBox(height: 12),
          Text(
            'No events for this filter',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
