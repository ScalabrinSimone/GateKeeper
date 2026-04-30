import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../core/models/models.dart'; // RfidObject, ObjectStatus, ObjectCategory, kFakeObjectsJson
import '../../shared/widgets/gk_empty_state.dart';
import '../../shared/widgets/gk_search_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../theme/app_colors.dart';
import 'dialogs/add_object_dialog.dart';
import 'widgets/object_card.dart';

// ---------------------------------------------------------------------------
// Dati stub — derivati dal modello core
// ---------------------------------------------------------------------------

// Usiamo kFakeObjectsJson (definita in rfid_object.dart) per costruire
// la lista di oggetti fake. Non possiamo usare 'const' perché RfidObject
// contiene DateTime? (non const-constructible).
//
// TODO: rimpiazzare con GET /api/objects dal backend.
final _stubObjects =
    kFakeObjectsJson.map(RfidObject.fromJson).toList();

// Categorie distinte presenti negli stub — usate per il filtro categoria.
// In produzione verranno dal backend (o derivate dalla lista oggetti).
final _allCategories = _stubObjects
    .map((o) => o.category)
    .toSet()
    .toList()
  ..sort((a, b) => a.name.compareTo(b.name));

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Schermata gestione oggetti RFID.
///
/// Filtri:
/// - **Ricerca testuale**: nome, tag RFID
/// - **Stato**: All / At Home / Away  →  [ObjectStatus.inside] / [ObjectStatus.outside]
/// - **Categoria**: All / Keys / Electronics / ecc.  →  [ObjectCategory]
///
/// Layout:
/// - Desktop: SearchBar + filtri stato + filtro categoria in riga (come Figma)
/// - Mobile: SearchBar → filtri stato → filtro categoria (impilati)
///
/// TODO: GET /api/objects per dati reali.
class ObjectsScreen extends StatefulWidget {
  const ObjectsScreen({super.key});

  @override
  State<ObjectsScreen> createState() => _ObjectsScreenState();
}

class _ObjectsScreenState extends State<ObjectsScreen> {
  String _query = '';

  // null = tutti gli stati
  ObjectStatus? _statusFilter;

  // null = tutte le categorie
  ObjectCategory? _categoryFilter;

  /// Applica tutti i filtri attivi sulla lista stub.
  List<RfidObject> get _filtered {
    return _stubObjects.where((o) {
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          o.name.toLowerCase().contains(q) ||
          o.rfidTag.toLowerCase().contains(q) ||
          o.category.name.toLowerCase().contains(q);

      final matchesStatus =
          _statusFilter == null || o.status == _statusFilter;

      final matchesCategory =
          _categoryFilter == null || o.category == _categoryFilter;

      return matchesQuery && matchesStatus && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AppBreakpoints.objectsMobile;

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
                  isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Filtri ─────────────────────────────────────────────
                  if (isMobile) ...[  
                    GkSearchBar(
                      hint: 'Search by name or RFID tag…',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 10),
                    _StatusFilterRow(
                      current: _statusFilter,
                      onChanged: (s) => setState(() => _statusFilter = s),
                    ),
                    const SizedBox(height: 8),
                    _CategoryFilterRow(
                      current: _categoryFilter,
                      categories: _allCategories,
                      onChanged: (c) => setState(() => _categoryFilter = c),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: GkSearchBar(
                            hint: 'Search by name or RFID tag…',
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusFilterRow(
                          current: _statusFilter,
                          onChanged: (s) => setState(() => _statusFilter = s),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1, height: 28, color: AppColors.border),
                        const SizedBox(width: 8),
                        _CategoryFilterRow(
                          current: _categoryFilter,
                          categories: _allCategories,
                          onChanged: (c) => setState(() => _categoryFilter = c),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ── Griglia / lista oggetti ────────────────────────────
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
                        for (var i = 0; i < _filtered.length; i++) ...[  
                          ObjectCard(
                            object: _filtered[i],
                            animationIndex: i,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 200,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => ObjectCard(
                        object: _filtered[i],
                        animationIndex: i,
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

// ---------------------------------------------------------------------------
// Widget locali
// ---------------------------------------------------------------------------

class _AddObjectButton extends StatelessWidget {
  const _AddObjectButton({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => AddObjectDialog.show(context),
      icon: const Icon(Icons.add, size: 18),
      label: isMobile ? const SizedBox.shrink() : const Text('Add Object'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.stormyTeal,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 18, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}

/// Riga chip filtro stato: All / At Home (inside) / Away (outside).
///
/// Parametri:
/// - [current]: stato attivo (null = All)
/// - [onChanged]: callback al cambio
class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.current,
    required this.onChanged,
  });

  final ObjectStatus? current;
  final ValueChanged<ObjectStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
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
            // ObjectStatus.inside = oggetto dentro casa
            isSelected: current == ObjectStatus.inside,
            onTap: () => onChanged(ObjectStatus.inside),
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Away',
            // ObjectStatus.outside = oggetto uscito di casa
            isSelected: current == ObjectStatus.outside,
            onTap: () => onChanged(ObjectStatus.outside),
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

/// Riga chip filtro categoria.
///
/// Parametri:
/// - [current]: categoria attiva (null = All)
/// - [categories]: lista [ObjectCategory] disponibili
/// - [onChanged]: callback al cambio
class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.current,
    required this.categories,
    required this.onChanged,
  });

  final ObjectCategory? current;
  final List<ObjectCategory> categories;
  final ValueChanged<ObjectCategory?> onChanged;

  /// Converte l'enum in etichetta leggibile per il chip.
  String _label(ObjectCategory cat) {
    return switch (cat) {
      ObjectCategory.keys        => 'Keys',
      ObjectCategory.umbrella    => 'Umbrella',
      ObjectCategory.bag         => 'Bag',
      ObjectCategory.electronics => 'Electronics',
      ObjectCategory.documents   => 'Documents',
      ObjectCategory.clothing    => 'Clothing',
      ObjectCategory.other       => 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All Categories',
            isSelected: current == null,
            onTap: () => onChanged(null),
          ),
          for (final cat in categories) ...[  
            const SizedBox(width: 8),
            _FilterChip(
              label: _label(cat),
              isSelected: current == cat,
              onTap: () => onChanged(cat),
              color: AppColors.stormyTealBright,
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip filtro animato generico.
///
/// Parametri:
/// - [label]: testo del chip
/// - [isSelected]: true = stile attivo
/// - [onTap]: callback al tap
/// - [color]: colore accent (default teal)
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
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
