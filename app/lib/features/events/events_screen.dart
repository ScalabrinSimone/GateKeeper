import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../core/services/haptic_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/event_detail_sheet.dart';

// ---------------------------------------------------------------------------
// Modelli
// ---------------------------------------------------------------------------

/// Direzione dell'evento rispetto alla porta: entrata o uscita.
enum EventDirection { out, in_ }

/// Tipo di evento generato dal gateway GateKeeper.
///
/// - [exit]: oggetto/utente rilevati in uscita dalla porta
/// - [entry]: oggetto/utente rilevati in entrata
/// - [alert]: evento anomalo (bambino senza telefono, oggetto sensibile fuori, ecc.)
/// - [scan]: scansione RFID generica senza movimento porta associato
enum EventType { exit, entry, alert, scan }

/// Singolo evento registrato dal gateway.
///
/// Esempio di costruzione:
/// ```dart
/// GkEvent(
///   id: 'e1',
///   type: EventType.exit,
///   direction: EventDirection.out,
///   timestamp: DateTime.now(),
///   userName: 'Alice',
///   objectNames: ['House Keys', 'Laptop Bag'],
/// )
/// ```
///
/// Parametri:
/// - [id]: identificatore univoco (UUID in produzione)
/// - [type]: tipo di evento ([EventType])
/// - [direction]: direzione del passaggio ([EventDirection])
/// - [timestamp]: data/ora dell'evento (UTC sul backend, locale in display)
/// - [userName]: nome dell'utente associato (null se non identificato via BLE)
/// - [objectNames]: oggetti RFID rilevati durante l'evento
/// - [alertMessage]: messaggio alert se [type] == [EventType.alert]
///
/// TODO: aggiungere campo [userAvatarUrl] quando il backend avrà gli avatar.
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
/// La paginazione sarà gestita con un cursore timestamp:
/// GET /api/events?before={timestamp}&limit=20
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
  GkEvent(
    id: 'e6',
    type: EventType.entry,
    direction: EventDirection.in_,
    timestamp:
        DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    userName: 'Charlie',
    objectNames: ['Car Keys'],
  ),
  GkEvent(
    id: 'e7',
    type: EventType.exit,
    direction: EventDirection.out,
    timestamp:
        DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    userName: 'Bob',
    objectNames: ['Wallet'],
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata storico eventi gateway.
///
/// Layout:
/// - Mobile: lista card con filtri chip
/// - Desktop: tabella con colonne (Timestamp, Type, Description, User, Objects)
///   + search bar, filtri data/tipo/utente, Export CSV
///
/// Filtri:
/// - Per tipo: All / Exits / Entries / Alerts / Scans
/// - Per testo: ricerca su userName e objectNames
///
/// TODO: paginazione infinita con scroll listener + cursore timestamp.
/// TODO: filtro per data con DateRangePicker.
/// TODO: Export CSV: chiamare GET /api/events/export.csv
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventType? _activeFilter;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _filters = <(EventType?, String)>[
    (null, 'All'),
    (EventType.exit, 'Exits'),
    (EventType.entry, 'Entries'),
    (EventType.alert, 'Alerts'),
    (EventType.scan, 'Scans'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Filtra gli eventi in base al tipo e alla query di ricerca.
  List<GkEvent> get _filteredEvents {
    var events = _activeFilter == null
        ? _stubEvents
        : _stubEvents.where((e) => e.type == _activeFilter).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      events = events
          .where((e) =>
              (e.userName?.toLowerCase().contains(q) ?? false) ||
              e.objectNames.any((o) => o.toLowerCase().contains(q)) ||
              (e.alertMessage?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppBreakpoints.desktop;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con titolo + Export CSV (solo desktop)
              PageHeader(
                title: isDesktop ? 'System Event Logs' : 'Event Logs',
                trailing: isDesktop
                    ? OutlinedButton.icon(
                        // TODO: chiamare GET /api/events/export.csv
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined,
                            size: 16),
                        label: const Text('Export CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side:
                              const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : null,
              ),

              // ── Desktop: search bar + filtri ──────────────────────────────
              if (isDesktop) _DesktopFilterBar(
                searchCtrl: _searchCtrl,
                searchQuery: _searchQuery,
                onSearchChanged: (v) =>
                    setState(() => _searchQuery = v),
                activeFilter: _activeFilter,
                filters: _filters,
                onFilterChanged: (f) =>
                    setState(() => _activeFilter = f),
              ),

              // ── Mobile: chip filtri ───────────────────────────────────────
              if (!isDesktop)
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
                              duration:
                                  const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.stormyTeal
                                    : AppColors.panelSoft,
                                borderRadius:
                                    BorderRadius.circular(20),
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

              // Lista o tabella eventi
              Expanded(
                child: _filteredEvents.isEmpty
                    ? const _EmptyEvents()
                    : isDesktop
                        ? _DesktopEventsTable(
                            events: _filteredEvents,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 24),
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
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop: filter bar
// ---------------------------------------------------------------------------

/// Barra filtri desktop: search + dropdown tipo + dropdown utente.
///
/// Parametri:
/// - [searchCtrl]: controller del campo di ricerca
/// - [onSearchChanged]: callback al cambio del testo
/// - [activeFilter]: filtro tipo corrente (null = All)
/// - [filters]: lista dei filtri disponibili
/// - [onFilterChanged]: callback al cambio del filtro tipo
class _DesktopFilterBar extends StatelessWidget {
  const _DesktopFilterBar({
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.filters,
    required this.onFilterChanged,
  });

  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final EventType? activeFilter;
  final List<(EventType?, String)> filters;
  final ValueChanged<EventType?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search logs (users, objects, events)...',
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textMuted, size: 18),
              filled: true,
              fillColor: AppColors.panel,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.stormyTeal),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtri in riga
          Row(
            children: [
              // Filtro data (stub)
              _FilterDropdown(
                icon: Icons.calendar_today_outlined,
                label: 'Last 7 Days',
                // TODO: DateRangePicker
                onTap: () {},
              ),
              const SizedBox(width: 10),
              // Filtro tipo evento
              _FilterDropdown(
                icon: Icons.filter_list_outlined,
                label: activeFilter == null
                    ? 'All Event Types'
                    : activeFilter.toString().split('.').last,
                onTap: () {
                  // Cicla tra i tipi di filtro al tap (semplice per ora)
                  // TODO: sostituire con DropdownMenu quando i filtri saranno più complessi
                  final currentIdx = filters
                      .indexWhere((f) => f.$1 == activeFilter);
                  final nextIdx =
                      (currentIdx + 1) % filters.length;
                  onFilterChanged(filters[nextIdx].$1);
                },
              ),
              const SizedBox(width: 10),
              // Filtro utente (stub)
              _FilterDropdown(
                icon: Icons.person_outline,
                label: 'All Users',
                // TODO: lista utenti da backend
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip dropdown filtro riutilizzabile.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop: tabella eventi
// ---------------------------------------------------------------------------

/// Tabella eventi in stile Figma: header con colonne fisse + righe dati.
///
/// Colonne: TIMESTAMP | TYPE | EVENT DESCRIPTION | USER | ASSOCIATED OBJECTS
class _DesktopEventsTable extends StatelessWidget {
  const _DesktopEventsTable({required this.events});
  final List<GkEvent> events;

  // Gruppa gli eventi per data (Today / Yesterday / data)
  Map<String, List<GkEvent>> get _grouped {
    final map = <String, List<GkEvent>>{};
    for (final e in events) {
      final key = _dayLabel(e.timestamp);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // ── Header colonne ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text('TIMESTAMP',
                        style: AppTextStyles.label),
                  ),
                  SizedBox(
                    width: 50,
                    child:
                        Text('TYPE', style: AppTextStyles.label),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('EVENT DESCRIPTION',
                        style: AppTextStyles.label),
                  ),
                  Expanded(
                    flex: 2,
                    child:
                        Text('USER', style: AppTextStyles.label),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('ASSOCIATED OBJECTS',
                        style: AppTextStyles.label),
                  ),
                ],
              ),
            ),
            // ── Righe raggruppate per data ──────────────────────────────────
            Expanded(
              child: ListView(
                children: [
                  for (final entry in _grouped.entries) ...[  
                    // Separatore gruppo data
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 14, 16, 6),
                      child: Text(
                        entry.key,
                        style: AppTextStyles.label,
                      ),
                    ),
                    const Divider(
                        color: AppColors.border, height: 1),
                    // Righe del gruppo
                    ...entry.value.map(
                      (event) => _DesktopEventRow(
                        event: event,
                        onTap: () => EventDetailSheet.show(
                          context,
                          event: event,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Singola riga della tabella eventi desktop.
class _DesktopEventRow extends StatelessWidget {
  const _DesktopEventRow({
    required this.event,
    required this.onTap,
  });
  final GkEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(event.type);
    final timeStr =
        '${event.timestamp.hour.toString().padLeft(2, '0')}:'
        '${event.timestamp.minute.toString().padLeft(2, '0')}:'
        '${event.timestamp.second.toString().padLeft(2, '0')} '
        '${event.timestamp.hour < 12 ? 'AM' : 'PM'}';

    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.panel.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Timestamp
            SizedBox(
              width: 120,
              child: Text(
                timeStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Icona tipo con colore
            SizedBox(
              width: 50,
              child: Icon(
                _typeIcon(event.type),
                color: typeColor,
                size: 18,
              ),
            ),
            // Descrizione evento
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventTitle(event),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.alertMessage != null)
                    Text(
                      event.alertMessage!,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    )
                  else
                    Text(
                      _eventSubtitle(event),
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    ),
                ],
              ),
            ),
            // Utente
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (event.userName != null) ...[  
                    CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          AppColors.stormyTeal.withValues(alpha: 0.2),
                      child: Text(
                        event.userName![0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.stormyTealBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    event.userName ?? 'System / Unknown',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Oggetti associati
            Expanded(
              flex: 2,
              child: event.objectNames.isEmpty
                  ? const Text('—',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: event.objectNames.map((obj) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.label_outline,
                                size: 11,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                obj,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(EventType type) => switch (type) {
        EventType.exit  => AppColors.warning,
        EventType.entry => AppColors.success,
        EventType.alert => AppColors.error,
        EventType.scan  => AppColors.stormyTealBright,
      };

  IconData _typeIcon(EventType type) => switch (type) {
        EventType.exit  => Icons.arrow_forward,
        EventType.entry => Icons.arrow_back,
        EventType.alert => Icons.warning_amber_outlined,
        EventType.scan  => Icons.nfc_outlined,
      };

  String _eventTitle(GkEvent e) => switch (e.type) {
        EventType.exit  => 'User Departed',
        EventType.entry => 'User Arrived',
        EventType.alert => 'Alert',
        EventType.scan  => 'System',
      };

  String _eventSubtitle(GkEvent e) => switch (e.type) {
        EventType.exit  => 'Authenticated via BLE node',
        EventType.entry => 'Authenticated via BLE node',
        EventType.alert => '',
        EventType.scan  => 'Daily automated gateway health check completed',
      };
}

// ---------------------------------------------------------------------------
// Mobile: tile evento
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
            // Barra colorata sinistra — indica il tipo di evento
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
            Icon(_typeIcon(event.type), color: typeColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.userName ?? 'Unknown user',
                    style: AppTextStyles.cardTitle
                        .copyWith(fontSize: 14),
                  ),
                  if (event.objectNames.isNotEmpty)
                    Text(
                      event.objectNames.join(', '),
                      style: AppTextStyles.body
                          .copyWith(fontSize: 12),
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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_timeAgo(event.timestamp),
                      style: AppTextStyles.label),
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

  Color _typeColor(EventType type) => switch (type) {
        EventType.exit  => AppColors.warning,
        EventType.entry => AppColors.success,
        EventType.alert => AppColors.error,
        EventType.scan  => AppColors.stormyTealBright,
      };

  IconData _typeIcon(EventType type) => switch (type) {
        EventType.exit  => Icons.logout,
        EventType.entry => Icons.login,
        EventType.alert => Icons.warning_amber_outlined,
        EventType.scan  => Icons.nfc_outlined,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
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
          Icon(Icons.history_outlined,
              color: AppColors.textMuted, size: 48),
          SizedBox(height: 12),
          Text(
            'No events for this filter',
            style:
                TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
