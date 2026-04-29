import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/gk_badge.dart';
import '../../shared/widgets/gk_empty_state.dart';
import '../../shared/widgets/gk_search_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/event_list_tile.dart';

// ---------------------------------------------------------------------------
// Modello dati
// ---------------------------------------------------------------------------

/// Tipo di evento generato dal sistema GateKeeper.
enum EventType { entry, exit, alert, forgotten, unauthorized }

/// Singolo evento del log.
///
/// Parametri:
/// - [id]: identificatore univoco
/// - [type]: categoria dell'evento
/// - [title]: titolo breve
/// - [description]: dettaglio esteso
/// - [user]: nome utente associato (può essere null per eventi senza utente)
/// - [object]: nome oggetto associato (null se non pertinente)
/// - [timestamp]: orario evento
class GkEvent {
  const GkEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.user,
    this.object,
    required this.timestamp,
  });

  final String id;
  final EventType type;
  final String title;
  final String description;
  final String? user;
  final String? object;
  final String timestamp;
}

// ---------------------------------------------------------------------------
// Dati stub
// ---------------------------------------------------------------------------

/// TODO: rimpiazzare con GET /api/events?limit=50 dal backend.
final _stubEvents = [
  const GkEvent(
    id: 'EVT-001',
    type: EventType.unauthorized,
    title: 'Unauthorized Exit',
    description:
        'Object left the house without any authenticated user nearby.',
    object: 'MacBook Pro',
    timestamp: 'Today, 10:45 AM',
  ),
  const GkEvent(
    id: 'EVT-002',
    type: EventType.forgotten,
    title: 'Forgotten Item',
    description: 'Bob left the house but forgot an essential item.',
    user: 'Bob',
    object: 'Wallet',
    timestamp: 'Today, 09:15 AM',
  ),
  const GkEvent(
    id: 'EVT-003',
    type: EventType.entry,
    title: 'Alice Arrived Home',
    description: 'Entered with authenticated BLE node.',
    user: 'Alice',
    object: 'House Keys',
    timestamp: 'Today, 08:30 AM',
  ),
  const GkEvent(
    id: 'EVT-004',
    type: EventType.exit,
    title: 'Bob Left Home',
    description: 'Exit detected. MacBook Pro and Wallet tracked.',
    user: 'Bob',
    timestamp: 'Today, 09:10 AM',
  ),
  const GkEvent(
    id: 'EVT-005',
    type: EventType.alert,
    title: 'Child Unaccompanied',
    description: 'Charlie exited without an adult present.',
    user: 'Charlie',
    timestamp: 'Yesterday, 03:30 PM',
  ),
  const GkEvent(
    id: 'EVT-006',
    type: EventType.entry,
    title: 'Dave Arrived Home',
    description: 'Entry confirmed via BLE.',
    user: 'Dave',
    timestamp: 'Yesterday, 04:00 PM',
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata log eventi.
///
/// Mostra tutti gli eventi in ordine cronologico inverso.
/// Supporta:
/// - ricerca testuale;
/// - filtro per tipo evento;
/// - dettaglio evento (TODO Blocco 2B: bottom sheet).
///
/// TODO (Blocco 2B): tap su evento → bottom sheet con dettaglio completo.
/// TODO: WebSocket / polling per ricevere nuovi eventi in realtime.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';
  EventType? _typeFilter;

  List<GkEvent> get _filtered {
    return _stubEvents.where((e) {
      final matchesQuery =
          e.title.toLowerCase().contains(_query.toLowerCase()) ||
              e.description.toLowerCase().contains(_query.toLowerCase()) ||
              (e.user?.toLowerCase().contains(_query.toLowerCase()) ?? false) ||
              (e.object?.toLowerCase().contains(_query.toLowerCase()) ??
                  false);
      final matchesType =
          _typeFilter == null || e.type == _typeFilter;
      return matchesQuery && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'Event Logs'),
              // Barra ricerca + filtri — sticky sopra la lista
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  0,
                  isMobile ? 16 : 24,
                  12,
                ),
                child: Column(
                  children: [
                    GkSearchBar(
                      hint: 'Search events, users or objects…',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 10),
                    _TypeFilterRow(
                      current: _typeFilter,
                      onChanged: (t) => setState(() => _typeFilter = t),
                    ),
                  ],
                ),
              ),

              // Lista eventi
              Expanded(
                child: _filtered.isEmpty
                    ? const GkEmptyState(
                        icon: Icons.history_toggle_off_outlined,
                        title: 'No events found',
                        subtitle:
                            'Try a different search or filter.',
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : 24,
                          0,
                          isMobile ? 16 : 24,
                          24,
                        ),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => EventListTile(
                          event: _filtered[i],
                          onTap: () {
                            // TODO (Blocco 2B): aprire bottom sheet dettaglio evento
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Filtro per tipo evento
// ---------------------------------------------------------------------------

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({
    required this.current,
    required this.onChanged,
  });

  final EventType? current;
  final ValueChanged<EventType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TypeChip(
            label: 'All',
            isSelected: current == null,
            onTap: () => onChanged(null),
          ),
          ...[EventType.alert, EventType.unauthorized, EventType.forgotten,
           EventType.entry, EventType.exit]
              .map((t) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _TypeChip(
                      label: _typeLabel(t),
                      color: _typeColor(t),
                      isSelected: current == t,
                      onTap: () => onChanged(t),
                    ),
                  )),
        ],
      ),
    );
  }

  String _typeLabel(EventType t) => switch (t) {
        EventType.entry => 'Entry',
        EventType.exit => 'Exit',
        EventType.alert => 'Alert',
        EventType.forgotten => 'Forgotten',
        EventType.unauthorized => 'Unauthorized',
      };

  Color _typeColor(EventType t) => switch (t) {
        EventType.entry => AppColors.success,
        EventType.exit => AppColors.stormyTealBright,
        EventType.alert => AppColors.warning,
        EventType.forgotten => AppColors.orange,
        EventType.unauthorized => const Color(0xFFFF4D4D),
      };
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.stormyTealBright;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? c.withValues(alpha: 0.18)
              : AppColors.panelSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? c.withValues(alpha: 0.55)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
