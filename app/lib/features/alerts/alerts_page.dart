import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/realtime_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';

//Pagina alert: mostra SOLO gli eventi critici (severity == critical).
//Gli alert si risolvono UNO PER UNO con il pulsante "Risolto".
//Non c'è pulsante "Segna tutti come letti".
//Quando un alert viene risolto, rimane visibile con animazione di dissolvenza
//per qualche secondo poi scompare.
//Nel registro eventi (events_page) tutti gli eventi restano visibili sempre.
class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<GateEvent> _items = const [];
  bool _loading = true;
  //Set degli id risolti in questo sessione (UI-only: la persistenza richiederebbe endpoint).
  final Set<String> _resolvedIds = {};
  //Set degli id in animazione fade-out (risolti di recente ma ancora visibili).
  final Set<String> _fadingOut = {};

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.addListener(_onRealtimeUpdate);
    _syncFromRealtime();
    _load();
  }

  @override
  void dispose() {
    RealtimeService.instance.removeListener(_onRealtimeUpdate);
    super.dispose();
  }

  void _onRealtimeUpdate() {
    if (!mounted) return;
    _syncFromRealtime();
  }

  void _syncFromRealtime() {
    final rt = RealtimeService.instance;
    if (rt.events.isNotEmpty) {
      setState(() {
        _items = _filterCritical(rt.events);
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await EventsRepository.list();
      if (!mounted) return;
      setState(() {
        _items = _filterCritical(events);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  //Solo eventi critici.
  List<GateEvent> _filterCritical(List<GateEvent> all) =>
      all.where((e) => e.severity == EventSeverity.critical).toList(growable: false);

  //Risolvi un singolo alert: prima lo mette in fade-out, poi lo rimuove dalla vista.
  Future<void> _resolve(String id) async {
    HapticFeedback.mediumImpact();
    setState(() => _fadingOut.add(id));
    //Anche il GateEvent viene aggiornato in memoria come risolto
    //per propagare lo stato alla pagina notifiche (icona warning verde).
    final event = _items.firstWhere((e) => e.id == id, orElse: () => _items.first);
    event.resolved = true;
    event.linkedAlertResolved = true;

    //L'elemento rimane visibile 0.5s per dare feedback prima di sparire.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _resolvedIds.add(id);
      _fadingOut.remove(id);
    });
  }

  //Elementi visibili: alert non risolti + quelli in fade-out.
  List<GateEvent> get _visibleItems =>
      _items
          .where((e) => !_resolvedIds.contains(e.id) || _fadingOut.contains(e.id))
          .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final visible = _visibleItems;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.orangeGold));
    }

    return RefreshIndicator(
      color: AppColors.orangeGold,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.t('alerts'),
              subtitle: l10n.t('alertsHint'),
            ),
            if (visible.isEmpty)
              //Contenitore a piena larghezza con padding generoso.
              SizedBox(
                width: double.infinity,
                child: GKCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded,
                          size: 56,
                          color: AppColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Nessun messaggio',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final alert in visible) ...[
                _AlertCard(
                  key: ValueKey(alert.id),
                  event: alert,
                  isResolved: _resolvedIds.contains(alert.id),
                  isFadingOut: _fadingOut.contains(alert.id),
                  onResolve: _fadingOut.contains(alert.id)
                      ? null
                      : () => _resolve(alert.id),
                  languageCode: l10n.languageCode,
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    super.key,
    required this.event,
    required this.isResolved,
    required this.isFadingOut,
    required this.onResolve,
    required this.languageCode,
  });

  final GateEvent event;
  final bool isResolved;
  final bool isFadingOut;
  final VoidCallback? onResolve;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final df = DateFormat.Hm();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isFadingOut ? 0.0 : 1.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        offset: isFadingOut ? const Offset(0.0, -0.05) : Offset.zero,
        child: GKCard(
          borderRadius: 32,
          padding: const EdgeInsets.all(20),
          background: isResolved
              ? AppColors.success.withValues(alpha: 0.06)
              : AppColors.orangeGold.withValues(alpha: 0.06),
          borderColor: isResolved
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.orangeGold.withValues(alpha: 0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Icona alert.
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppColors.success
                      : AppColors.orangeGold,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isResolved
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: AppColors.inkBlack,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.descriptionFor(languageCode),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isResolved
                            ? AppColors.success
                            : AppColors.orangeGold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          df.format(event.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isResolved
                                    ? AppColors.success
                                    : AppColors.orangeGold)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isResolved
                                ? l10n.t('alertResolved').toUpperCase()
                                : 'CRITICAL',
                            style: TextStyle(
                              color: isResolved
                                  ? AppColors.success
                                  : AppColors.orangeGold,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    //Pulsante "Risolto" solo se non ancora risolto.
                    if (!isResolved && !isFadingOut)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: onResolve,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            l10n.t('markResolved'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    //Feedback visivo durante il fade-out.
                    if (isFadingOut)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              l10n.t('markResolved'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
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
      ),
    );
  }
}
