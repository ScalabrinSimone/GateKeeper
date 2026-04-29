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

/// Direzione del passaggio porta.
enum EventDirection { out, in_ }

/// Tipo di evento GateKeeper.
///
/// - [exit]: uscita dalla porta
/// - [entry]: entrata
/// - [alert]: evento anomalo (bambino senza telefono, oggetto sensibile, ecc.)
/// - [scan]: scansione RFID generica senza movimento porta
enum EventType { exit, entry, alert, scan }

/// Singolo evento registrato dal gateway.
///
/// Esempio:
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
/// - [type]: tipo evento [EventType]
/// - [direction]: direzione passaggio [EventDirection]
/// - [timestamp]: data/ora UTC dal backend, visualizzata come locale
/// - [userName]: utente BLE associato (null = non identificato)
/// - [objectNames]: tag RFID rilevati
/// - [alertMessage]: testo alert se [type] == [EventType.alert]
///
/// TODO: aggiungere [userAvatarUrl] quando il backend avrà gli avatar.
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

/// TODO: rimpiazzare con GET /api/events?before={timestamp}&limit=20
final _stubEvents = [
  GkEvent(
    id: 'e1',
    type: EventType.alert,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(hours: 0, minutes: 15)),
    userName: null,
    alertMessage: 'Object passed gateway without authenticated BLE device',
    objectNames: ['MacBook Pro'],
  ),
  GkEvent(
    id: 'e2',
    type: EventType.scan,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(hours: 0, minutes: 45)),
    userName: 'Bob',
    alertMessage: 'User exited but usually carries tagged item',
    objectNames: ['Wallet'],
  ),
  GkEvent(
    id: 'e3',
    type: EventType.entry,
    direction: EventDirection.in_,
    timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    userName: 'Alice',
    objectNames: ['House Keys', 'Backpack'],
  ),
  GkEvent(
    id: 'e4',
    type: EventType.exit,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    userName: 'Charlie',
    objectNames: ['Car Keys'],
  ),
  GkEvent(
    id: 'e5',
    type: EventType.scan,
    direction: EventDirection.in_,
    timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    objectNames: [],
    alertMessage: 'Daily automated gateway health check completed',
  ),
  GkEvent(
    id: 'e6',
    type: EventType.entry,
    direction: EventDirection.in_,
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    userName: 'Charlie',
    objectNames: ['Car Keys'],
  ),
  GkEvent(
    id: 'e7',
    type: EventType.exit,
    direction: EventDirection.out,
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    userName: 'Bob',
    objectNames: ['Wallet'],
  ),
];

// Utenti distinti negli stub — usati dal filtro utente desktop
final _stubUsers = _stubEvents
    .map((e) => e.userName)
    .whereType<String>()
    .toSet()
    .toList()
  ..sort();

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata storico eventi gateway.
///
/// Filtri disponibili:
/// - **Tipo**: All / Exits / Entries / Alerts / Scans
/// - **Data**: Today / Last 7 Days / Last 30 Days / All Time
/// - **Utente**: tutti gli utenti o uno specifico
/// - **Testo**: ricerca libera su userName, objectNames, alertMessage
///
/// Layout desktop: barra filtri su RIGA SINGOLA (search + 3 dropdown affiancati).
/// Layout mobile: search + chip tipo su righe compatte.
///
/// TODO: paginazione infinita con cursore timestamp.
/// TODO: Export CSV → GET /api/events/export.csv
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventType? _typeFilter;
  String? _userFilter; // null = tutti gli utenti
  _DateRange _dateRange = _DateRange.last7Days;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _typeFilters = <(EventType?, String)>[
    (null, 'All Event Types'),
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

  /// Applica tutti i filtri attivi agli eventi stub.
  List<GkEvent> get _filteredEvents {
    var events = _stubEvents.toList();

    if (_typeFilter != null) {
      events = events.where((e) => e.type == _typeFilter).toList();
    }
    if (_userFilter != null) {
      events = events.where((e) => e.userName == _userFilter).toList();
    }
    final cutoff = _dateRange.cutoff;
    if (cutoff != null) {
      events = events.where((e) => e.timestamp.isAfter(cutoff)).toList();
    }
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
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              PageHeader(
                title: isDesktop ? 'System Event Logs' : 'Event Logs',
                trailing: isDesktop
                    ? OutlinedButton.icon(
                        onPressed: () {}, // TODO: GET /api/events/export.csv
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Export CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : null,
              ),

              // ── Desktop: filtri tutti su riga singola ─────────────────────
              // Search + dropdown Data + dropdown Tipo + dropdown Utente
              // sono tutti in Row affiancati dentro un container.
              if (isDesktop)
                _DesktopFilterBar(
                  searchCtrl: _searchCtrl,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  typeFilter: _typeFilter,
                  onTypeChanged: (f) => setState(() => _typeFilter = f),
                  userFilter: _userFilter,
                  onUserChanged: (u) => setState(() => _userFilter = u),
                  dateRange: _dateRange,
                  onDateChanged: (d) => setState(() => _dateRange = d),
                  availableUsers: _stubUsers,
                  typeFilters: _typeFilters,
                ),

              // ── Mobile: search + chip tipo ────────────────────────────────
              if (!isDesktop) ...
                [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search logs (users, objects, events)...',
                        hintStyle:
                            const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMuted, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.panelSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.stormyTeal),
                        ),
                      ),
                    ),
                  ),
                  // Chip filtro tipo a scorrimento orizzontale
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _typeFilters.map((f) {
                          final (type, label) = f;
                          final active = _typeFilter == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () async {
                                await HapticService.light();
                                setState(() => _typeFilter = type);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
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
                ],

              // ── Lista / tabella eventi ────────────────────────────────────
              Expanded(
                child: _filteredEvents.isEmpty
                    ? const _EmptyEvents()
                    : isDesktop
                        ? _DesktopEventsTable(events: _filteredEvents)
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, i) => _EventTile(
                              event: _filteredEvents[i],
                              onTap: () => EventDetailSheet.show(
                                context,
                                event: _filteredEvents[i],
                              ),
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
// Enum filtro data
// ---------------------------------------------------------------------------

/// Range temporale per il filtro data degli eventi.
///
/// - [today]: solo eventi di oggi
/// - [last7Days]: ultimi 7 giorni (default)
/// - [last30Days]: ultimi 30 giorni
/// - [allTime]: nessun limite temporale
enum _DateRange {
  today,
  last7Days,
  last30Days,
  allTime;

  String get label => switch (this) {
        _DateRange.today => 'Today',
        _DateRange.last7Days => 'Last 7 Days',
        _DateRange.last30Days => 'Last 30 Days',
        _DateRange.allTime => 'All Time',
      };

  DateTime? get cutoff {
    final now = DateTime.now();
    return switch (this) {
      _DateRange.today =>
        DateTime(now.year, now.month, now.day),
      _DateRange.last7Days => now.subtract(const Duration(days: 7)),
      _DateRange.last30Days => now.subtract(const Duration(days: 30)),
      _DateRange.allTime => null,
    };
  }
}

// ---------------------------------------------------------------------------
// Desktop: barra filtri su RIGA SINGOLA
// ---------------------------------------------------------------------------

/// Barra filtri desktop.
///
/// Tutti i controlli sono su una singola riga:
/// [search (Expanded)] [dropdown Data] [dropdown Tipo] [dropdown Utente]
///
/// La search occupa lo spazio restante con [Expanded]; i dropdown hanno
/// dimensione minima intrinseca. Questo replica esattamente il mockup Figma.
///
/// Parametri:
/// - [searchCtrl]: controller TextField ricerca
/// - [onSearchChanged]: callback cambio testo
/// - [typeFilter]: filtro tipo attivo (null = All)
/// - [onTypeChanged]: callback cambio tipo
/// - [userFilter]: nome utente filtrato (null = All Users)
/// - [onUserChanged]: callback cambio utente
/// - [dateRange]: range data attivo
/// - [onDateChanged]: callback cambio range
/// - [availableUsers]: lista utenti per il dropdown
/// - [typeFilters]: lista coppie (EventType?, label)
class _DesktopFilterBar extends StatelessWidget {
  const _DesktopFilterBar({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.typeFilter,
    required this.onTypeChanged,
    required this.userFilter,
    required this.onUserChanged,
    required this.dateRange,
    required this.onDateChanged,
    required this.availableUsers,
    required this.typeFilters,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final EventType? typeFilter;
  final ValueChanged<EventType?> onTypeChanged;
  final String? userFilter;
  final ValueChanged<String?> onUserChanged;
  final _DateRange dateRange;
  final ValueChanged<_DateRange> onDateChanged;
  final List<String> availableUsers;
  final List<(EventType?, String)> typeFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      // ── Riga singola: search + 3 dropdown ──────────────────────────────
      // NOTA: in precedenza search e dropdown erano in Column separata;
      // ora sono tutti in Row così il layout replica il mockup.
      child: Row(
        children: [
          // Search bar — si espande per riempire lo spazio disponibile
          Expanded(
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search logs (users, objects, events)...',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textMuted, size: 16),
                filled: true,
                fillColor: AppColors.panel,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.stormyTeal),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Filtro data ────────────────────────────────────────────────
          _DropdownFilter<_DateRange>(
            icon: Icons.calendar_today_outlined,
            label: dateRange.label,
            items: _DateRange.values,
            labelFor: (d) => d.label,
            selected: dateRange,
            onSelected: onDateChanged,
          ),
          const SizedBox(width: 8),
          // ── Filtro tipo ────────────────────────────────────────────────
          _DropdownFilter<EventType?>(
            icon: Icons.filter_list_outlined,
            label: typeFilter == null
                ? 'All Event Types'
                : typeFilters
                    .firstWhere((f) => f.$1 == typeFilter,
                        orElse: () => (null, 'All Event Types'))
                    .$2,
            items: typeFilters.map((f) => f.$1).toList(),
            labelFor: (t) => typeFilters
                .firstWhere((f) => f.$1 == t,
                    orElse: () => (null, 'All Event Types'))
                .$2,
            selected: typeFilter,
            onSelected: onTypeChanged,
          ),
          const SizedBox(width: 8),
          // ── Filtro utente ──────────────────────────────────────────────
          _DropdownFilter<String?>(
            icon: Icons.person_outline,
            label: userFilter ?? 'All Users',
            items: [null, ...availableUsers],
            labelFor: (u) => u ?? 'All Users',
            selected: userFilter,
            onSelected: onUserChanged,
          ),
        ],
      ),
    );
  }
}

/// Dropdown filtro generico con [PopupMenuButton].
///
/// Apre un menu nativo con tutte le opzioni — il valore corrente
/// è evidenziato con un check mark e colore teal.
///
/// Parametri:
/// - [icon]: icona a sinistra del label
/// - [label]: testo del valore corrente
/// - [items]: lista di tutti i valori possibili
/// - [labelFor]: funzione che converte un item nel testo da mostrare
/// - [selected]: valore attualmente selezionato
/// - [onSelected]: callback quando l'utente sceglie un item
class _DropdownFilter<T> extends StatelessWidget {
  const _DropdownFilter({
    required this.icon,
    required this.label,
    required this.items,
    required this.labelFor,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final List<T> items;
  final String Function(T) labelFor;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      offset: const Offset(0, 40),
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 6,
      onSelected: onSelected,
      itemBuilder: (_) => items.map((item) {
        final isSelected = item == selected;
        return PopupMenuItem<T>(
          value: item,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: isSelected
                    ? const Icon(Icons.check,
                        size: 14, color: AppColors.stormyTealBright)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                labelFor(item),
                style: TextStyle(
                  color: isSelected
                      ? AppColors.stormyTealBright
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
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
// Desktop: tabella
// ---------------------------------------------------------------------------

/// Tabella eventi desktop con raggruppamento per data.
///
/// Colonne: TIMESTAMP | TYPE | EVENT DESCRIPTION | USER | ASSOCIATED OBJECTS
class _DesktopEventsTable extends StatelessWidget {
  const _DesktopEventsTable({required this.events});
  final List<GkEvent> events;

  Map<String, List<GkEvent>> get _grouped {
    final map = <String, List<GkEvent>>{};
    for (final e in events) {
      map.putIfAbsent(_dayLabel(e.timestamp), () => []).add(e);
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
            // Header colonne
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                      width: 120,
                      child:
                          Text('TIMESTAMP', style: AppTextStyles.label)),
                  SizedBox(
                      width: 60,
                      child: Text('TYPE', style: AppTextStyles.label)),
                  Expanded(
                      flex: 3,
                      child: Text('EVENT DESCRIPTION',
                          style: AppTextStyles.label)),
                  Expanded(
                      flex: 2,
                      child: Text('USER', style: AppTextStyles.label)),
                  Expanded(
                      flex: 2,
                      child: Text('ASSOCIATED OBJECTS',
                          style: AppTextStyles.label)),
                ],
              ),
            ),
            // Righe raggruppate per giorno
            Expanded(
              child: ListView(
                children: [
                  for (final entry in _grouped.entries) ...
                    [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(entry.key,
                            style: AppTextStyles.label),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      ...entry.value.map((event) => _DesktopEventRow(
                            event: event,
                            onTap: () => EventDetailSheet.show(
                                context,
                                event: event),
                          )),
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

/// Riga singola della tabella desktop.
class _DesktopEventRow extends StatelessWidget {
  const _DesktopEventRow({required this.event, required this.onTap});
  final GkEvent event;
  final VoidCallback onTap;

  Color get _typeColor => switch (event.type) {
        EventType.alert => AppColors.warning,
        EventType.entry => AppColors.success,
        EventType.exit => AppColors.stormyTealBright,
        EventType.scan => AppColors.textMuted,
      };

  IconData get _typeIcon => switch (event.type) {
        EventType.alert => Icons.warning_amber_outlined,
        EventType.entry => Icons.login_outlined,
        EventType.exit => Icons.logout_outlined,
        EventType.scan => Icons.sensors_outlined,
      };

  String get _typeLabel => switch (event.type) {
        EventType.alert => 'Alert',
        EventType.entry => 'Entry',
        EventType.exit => 'Exit',
        EventType.scan => 'Scan',
      };

  String get _description {
    if (event.alertMessage != null) return event.alertMessage!;
    final user = event.userName ?? 'Unknown';
    final dir =
        event.direction == EventDirection.out ? 'exited' : 'entered';
    final objs = event.objectNames.isEmpty
        ? 'no objects'
        : event.objectNames.join(', ');
    return '$user $dir with $objs';
  }

  String get _timeStr {
    final dt = event.timestamp;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m:$s $ap';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.panel.withValues(alpha: 0.5),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // Timestamp
            SizedBox(
              width: 120,
              child: Text(_timeStr,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
            // Badge tipo con icona
            SizedBox(
              width: 60,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_typeIcon, size: 14, color: _typeColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _typeLabel,
                      style: TextStyle(
                        color: _typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Descrizione
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _description,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Utente
            Expanded(
              flex: 2,
              child: Text(
                event.userName ?? 'System / Unknown',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Oggetti associati come chip
            Expanded(
              flex: 2,
              child: event.objectNames.isEmpty
                  ? const Text('—',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13))
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: event.objectNames
                          .map((obj) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.panel,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                child: Text(
                                  obj,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile mobile
// ---------------------------------------------------------------------------

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onTap});
  final GkEvent event;
  final VoidCallback onTap;

  Color get _color => switch (event.type) {
        EventType.alert => AppColors.warning,
        EventType.entry => AppColors.success,
        EventType.exit => AppColors.stormyTealBright,
        EventType.scan => AppColors.textMuted,
      };

  IconData get _icon => switch (event.type) {
        EventType.alert => Icons.warning_amber_outlined,
        EventType.entry => Icons.login_outlined,
        EventType.exit => Icons.logout_outlined,
        EventType.scan => Icons.wifi_tethering_outlined,
      };

  String get _title => switch (event.type) {
        EventType.alert => 'Alert',
        EventType.entry => 'Entry',
        EventType.exit => 'Exit',
        EventType.scan => 'Scan',
      };

  String get _desc {
    if (event.alertMessage != null) return event.alertMessage!;
    final u = event.userName ?? 'Unknown';
    final o = event.objectNames.isEmpty
        ? 'no objects'
        : event.objectNames.join(', ');
    return '$u — $o';
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Striscia colorata laterale: indica il tipo visivamente
                Container(width: 4, color: _color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_icon, color: _color, size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_title,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(_fmt(event.timestamp),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_desc,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 40),
          SizedBox(height: 12),
          Text(
            'No events match the current filters.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
