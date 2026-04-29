import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/gk_empty_state.dart';
import '../../shared/widgets/gk_search_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import 'dialogs/add_object_dialog.dart';
import 'widgets/object_card.dart';

// ---------------------------------------------------------------------------
// Modello dati locale
// ---------------------------------------------------------------------------

/// Stato attuale di un oggetto tracciato via RFID.
enum ObjectStatus { home, away, unknown }

/// Oggetto fisico con tag RFID registrato nel sistema.
///
/// Parametri:
/// - [id]: ID RFID dell'etichetta
/// - [name]: nome leggibile (es. 'Chiavi di casa')
/// - [category]: categoria (es. 'Keys', 'Electronics')
/// - [status]: posizione corrente
/// - [lastSeen]: ultima rilevazione (ISO 8601)
/// - [icon]: icona rappresentativa
class RfidObject {
  const RfidObject({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.lastSeen,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final ObjectStatus status;
  final String lastSeen;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// Dati stub
// ---------------------------------------------------------------------------

/// TODO: rimpiazzare con chiamata GET /api/objects dal backend.
const _stubObjects = [
  RfidObject(
    id: 'RFID-001',
    name: 'House Keys',
    category: 'Keys',
    status: ObjectStatus.home,
    lastSeen: 'Today, 08:30 AM',
    icon: Icons.vpn_key_outlined,
  ),
  RfidObject(
    id: 'RFID-002',
    name: 'MacBook Pro',
    category: 'Electronics',
    status: ObjectStatus.away,
    lastSeen: 'Today, 10:45 AM',
    icon: Icons.laptop_mac_outlined,
  ),
  RfidObject(
    id: 'RFID-003',
    name: 'Wallet',
    category: 'Accessories',
    status: ObjectStatus.away,
    lastSeen: 'Today, 09:15 AM',
    icon: Icons.wallet_outlined,
  ),
  RfidObject(
    id: 'RFID-004',
    name: 'Umbrella',
    category: 'Accessories',
    status: ObjectStatus.home,
    lastSeen: 'Yesterday, 06:00 PM',
    icon: Icons.umbrella_outlined,
  ),
  RfidObject(
    id: 'RFID-005',
    name: 'Car Keys',
    category: 'Keys',
    status: ObjectStatus.home,
    lastSeen: 'Today, 07:00 AM',
    icon: Icons.directions_car_outlined,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata gestione oggetti RFID.
///
/// Responsabilità:
/// - visualizza tutti gli oggetti registrati con stato e ultima rilevazione;
/// - filtro per ricerca testuale e stato (su una riga singola come da mockup);
/// - l'admin può aggiungere nuovi oggetti tramite [AddObjectDialog].
///
/// Layout filtri: [SearchBar] + [StatusFilterRow] nella stessa Row orizzontale.
///
/// TODO: chiamata GET /api/objects per popolare la lista.
class ObjectsScreen extends StatefulWidget {
  const ObjectsScreen({super.key});

  @override
  State<ObjectsScreen> createState() => _ObjectsScreenState();
}

class _ObjectsScreenState extends State<ObjectsScreen> {
  String _query = '';
  ObjectStatus? _statusFilter;

  List<RfidObject> get _filtered {
    return _stubObjects.where((o) {
      final matchesQuery =
          o.name.toLowerCase().contains(_query.toLowerCase()) ||
          o.category.toLowerCase().contains(_query.toLowerCase()) ||
          o.id.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus =
          _statusFilter == null || o.status == _statusFilter;
      return matchesQuery && matchesStatus;
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
              PageHeader(
                title: 'RFID Objects',
                trailing: _AddObjectButton(isMobile: isMobile),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    0,
                    isMobile ? 16 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Barra ricerca + filtri in riga (come da mockup Figma) ──
                      // Su desktop: SearchBar espansa + chips filtro sulla stessa riga.
                      // Su mobile: SearchBar sopra, chips sotto.
                      if (isMobile) ...
                        [
                          GkSearchBar(
                            hint: 'Search by name, category or RFID ID…',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 10),
                          _StatusFilterRow(
                            current: _statusFilter,
                            onChanged: (s) =>
                                setState(() => _statusFilter = s),
                          ),
                        ]
                      else
                        // Desktop: tutto in una riga
                        Row(
                          children: [
                            // SearchBar flessibile (occupa lo spazio disponibile)
                            Expanded(
                              child: GkSearchBar(
                                hint: 'Search by name, category or RFID ID…',
                                onChanged: (v) =>
                                    setState(() => _query = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Chips filtro a destra della search
                            _StatusFilterRow(
                              current: _statusFilter,
                              onChanged: (s) =>
                                  setState(() => _statusFilter = s),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Grid oggetti
                      if (_filtered.isEmpty)
                        const GkEmptyState(
                          icon: Icons.sell_outlined,
                          title: 'No objects found',
                          subtitle:
                              'Add a new RFID object or try a different search.',
                        )
                      else if (isMobile)
                        Column(
                          children: [
                            for (final obj in _filtered) ...
                              [
                                ObjectCard(object: obj),
                                const SizedBox(height: 12),
                              ],
                          ],
                        )
                      else
                        // Desktop: griglia con altezza fissa per card —
                        // mainAxisExtent evita il childAspectRatio che causava overflow.
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            // Altezza fissa per ogni card: evita overflow
                            // perché il contenuto (icona+nome+categoria+timestamp+id)
                            // è sempre inferiore a 190px.
                            mainAxisExtent: 190,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              ObjectCard(object: _filtered[i]),
                        ),
                    ],
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
// Widget locali
// ---------------------------------------------------------------------------

class _AddObjectButton extends StatelessWidget {
  const _AddObjectButton({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      // Collega AddObjectDialog (già implementato)
      onPressed: () => AddObjectDialog.show(context),
      icon: const Icon(Icons.add, size: 18),
      label: isMobile ? const SizedBox.shrink() : const Text('Add Object'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.stormyTeal,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 18,
          vertical: 10,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
    );
  }
}

/// Riga di filtri per stato oggetto: All / At Home / Away.
///
/// Non scrolla orizzontalmente su desktop perché vengono mostrati
/// solo 3 chip che entrano sempre nella riga accanto alla search.
class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.current,
    required this.onChanged,
  });

  final ObjectStatus? current;
  final ValueChanged<ObjectStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Su mobile potrebbe servire scroll orizzontale
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: current == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'At Home',
            isSelected: current == ObjectStatus.home,
            onTap: () => onChanged(ObjectStatus.home),
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Away',
            isSelected: current == ObjectStatus.away,
            onTap: () => onChanged(ObjectStatus.away),
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? c.withValues(alpha: 0.18)
              : AppColors.panelSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? c.withValues(alpha: 0.60)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
