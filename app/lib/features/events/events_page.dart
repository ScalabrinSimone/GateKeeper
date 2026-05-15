import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';

enum _RangeFilter { day, week, month }

enum _SeverityFilter { all, critical, info }

//Pagina cronologia eventi con filtri (giorno/settimana/mese e severità).
//Carica dal backend; in caso di errore usa i mock locali.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _search = '';
  _RangeFilter _range = _RangeFilter.day;
  _SeverityFilter _severity = _SeverityFilter.all;
  List<GateEvent> _events = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote = await EventsRepository.list();
      if (!mounted) return;
      setState(() {
        _events = remote;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _events = const [];
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _events = const [];
        _error = e.toString();
        _loading = false;
      });
    }
  }

  //Export rapido in clipboard (CSV-like). Niente file I/O qui per essere
  //compatibili con web/desktop senza permessi extra.
  Future<void> _exportEvents(AppL10n l10n, List<GateEvent> events) async {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('noEvents'))),
      );
      return;
    }
    final buf = StringBuffer('timestamp;type;severity;description\n');
    for (final e in events) {
      buf
        ..write(e.timestamp.toIso8601String())
        ..write(';')
        ..write(e.type.name)
        ..write(';')
        ..write(e.severity.name)
        ..write(';')
        ..write(e.descriptionFor(l10n.languageCode).replaceAll(';', ','))
        ..write('\n');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('exportCopied'))),
    );
  }

  List<GateEvent> _filtered(String langCode) {
    final now = DateTime.now();
    return _events.where((e) {
      final matchSearch = e.descriptionFor(langCode).toLowerCase().contains(_search.toLowerCase());
      final matchSeverity = _severity == _SeverityFilter.all
          || (_severity == _SeverityFilter.critical && e.severity == EventSeverity.critical)
          || (_severity == _SeverityFilter.info && e.severity == EventSeverity.info);
      final diff = now.difference(e.timestamp);
      bool inRange;
      switch (_range) {
        case _RangeFilter.day:
          inRange = diff.inDays < 1;
          break;
        case _RangeFilter.week:
          inRange = diff.inDays < 7;
          break;
        case _RangeFilter.month:
          inRange = diff.inDays < 30;
          break;
      }
      return matchSearch && matchSeverity && inRange;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final events = _filtered(l10n.languageCode);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.stormyTeal));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.stormyTeal,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.t('history'),
            subtitle: l10n.t('monitorMovements'),
            actions: [
              _RangeChips(value: _range, onChanged: (v) => setState(() => _range = v)),
              GKButton(
                onPressed: () => _exportEvents(l10n, events),
                label: l10n.t('exportLabel'),
                icon: Icons.download_rounded,
                variant: GKButtonVariant.secondary,
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            GKCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(14),
              borderColor: AppColors.danger.withValues(alpha: 0.3),
              background: AppColors.danger.withValues(alpha: 0.04),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!)),
                  GKButton(
                    onPressed: _load,
                    label: l10n.t('tryAgain'),
                    icon: Icons.refresh_rounded,
                    variant: GKButtonVariant.ghost,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          //Riga filtri search + severity.
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.t('searchEvents'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SeverityDropdown(
                  value: _severity,
                  onChanged: (v) => setState(() => _severity = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GKCard(
            borderRadius: 32,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < events.length; i++) ...[
                  _EventRow(event: events[i]),
                  if (i < events.length - 1)
                    Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
                ],
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t('noEvents'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.value, required this.onChanged});
  final _RangeFilter value;
  final ValueChanged<_RangeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.stormyTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(theme, l10n.t('viewDay'), value == _RangeFilter.day, () => onChanged(_RangeFilter.day)),
          _chip(theme, l10n.t('viewWeek'), value == _RangeFilter.week, () => onChanged(_RangeFilter.week)),
          _chip(theme, l10n.t('viewMonth'), value == _RangeFilter.month, () => onChanged(_RangeFilter.month)),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.stormyTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _SeverityDropdown extends StatelessWidget {
  const _SeverityDropdown({required this.value, required this.onChanged});
  final _SeverityFilter value;
  final ValueChanged<_SeverityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return DropdownButtonFormField<_SeverityFilter>(
      initialValue: value,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.filter_list_rounded, size: 20),
      ),
      items: [
        DropdownMenuItem(value: _SeverityFilter.all, child: Text(l10n.t('all'))),
        DropdownMenuItem(value: _SeverityFilter.critical, child: Text(l10n.t('critical'))),
        DropdownMenuItem(value: _SeverityFilter.info, child: Text(l10n.t('info'))),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final GateEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final critical = event.severity == EventSeverity.critical;
    final color = critical ? AppColors.orangeGold : AppColors.stormyTeal;
    final df = DateFormat.Hm();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              critical ? Icons.warning_amber_rounded : Icons.access_time_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.descriptionFor(l10n.languageCode),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: critical ? AppColors.orangeGold : null,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      df.format(event.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), shape: BoxShape.circle)),
                    Text(
                      _eventTypeLabel(l10n, event.type),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: AppColors.stormyTeal.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              critical ? 'CRITICAL' : 'SYSTEM',
              style: TextStyle(
                color: color,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _eventTypeLabel(AppL10n l10n, EventType type) {
    switch (type) {
      case EventType.entry:
        return l10n.t('entry');
      case EventType.exit:
        return l10n.t('exit');
      case EventType.risk:
        return l10n.t('risk');
      case EventType.system:
        return 'SYSTEM';
    }
  }
}
