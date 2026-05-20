import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/read_events_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/realtime_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';

//Pagina notifiche: mostra tutti gli eventi informativi (entrata/uscita/sistema).
//GLI ALERT CRITICI NON COMPAIONO QUI — stanno nella pagina /alerts.
//Se un evento normale ha generato un alert (hasAlert = true), viene mostrata
//un'icona warning gialla. Quando l'alert collegato viene risolto,
//l'icona diventa verde e la notifica può essere segnata come letta.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<GateEvent> _items = const [];
  bool _loading = true;
  //Set degli id in animazione di uscita (segnati letti di recente).
  //Lo stato "letto" viene gestito dal ReadEventsController globale.
  final Set<String> _fadingOut = {};

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.addListener(_onRealtimeUpdate);
    ReadEventsController.instance.addListener(_onReadChanged);
    _syncFromRealtime();
    _load();
  }

  @override
  void dispose() {
    RealtimeService.instance.removeListener(_onRealtimeUpdate);
    ReadEventsController.instance.removeListener(_onReadChanged);
    super.dispose();
  }

  void _onReadChanged() {
    if (mounted) setState(() {});
  }

  void _onRealtimeUpdate() {
    if (!mounted) return;
    _syncFromRealtime();
  }

  void _syncFromRealtime() {
    final rt = RealtimeService.instance;
    if (rt.events.isNotEmpty) {
      setState(() {
        _items = _filterNonCritical(rt.events);
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
        _items = _filterNonCritical(events);
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

  //Filtra: mostra solo eventi NON critici (entrata, uscita, sistema).
  List<GateEvent> _filterNonCritical(List<GateEvent> all) =>
      all.where((e) => e.severity != EventSeverity.critical).toList(growable: false);

  //Segna tutte le notifiche leggibili come lette con animazione.
  //Le notifiche con warning attivo non possono essere segnate finché l'alert non è risolto.
  Future<void> _markAllRead() async {
    HapticFeedback.mediumImpact();
    //Segna immediatamente come "in uscita" le notifiche senza warning attivo.
    final ctrl = ReadEventsController.instance;
    final toFade = _items
        .where((e) => !ctrl.isRead(e.id) && !_hasActiveWarning(e))
        .map((e) => e.id)
        .toList();

    if (toFade.isEmpty) return;

    setState(() {
      _fadingOut.addAll(toFade);
    });

    //Stessa velocità degli alerts: 500ms di attesa prima della scomparsa.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    //Propaga al controller globale (aggiorna anche Dashboard).
    ReadEventsController.instance.markAllRead(toFade);
    setState(() {
      _fadingOut.clear();
    });
  }

  //Segna una singola notifica come letta con animazione.
  Future<void> _markSingleRead(String id) async {
    HapticFeedback.selectionClick();
    setState(() => _fadingOut.add(id));
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    ReadEventsController.instance.markRead(id);
    setState(() {
      _fadingOut.remove(id);
    });
  }

  bool _hasActiveWarning(GateEvent event) => event.hasLinkedAlert;

  //Può essere segnata come letta solo se il warning è risolto (o non presente).
  bool _canMarkRead(GateEvent event) {
    if (ReadEventsController.instance.isRead(event.id)) return false;
    if (_hasActiveWarning(event) && !(event.linkedAlertResolved ?? false)) return false;
    return true;
  }

  //Elementi visibili: escludi quelli già letti (dal controller globale) tranne quelli in fade-out.
  List<GateEvent> get _visibleItems =>
      _items.where((e) =>
        !ReadEventsController.instance.isRead(e.id) || _fadingOut.contains(e.id)
      ).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final visible = _visibleItems;
    //Ci sono notifiche segnabili come lette?
    final hasReadable = visible.any((e) => _canMarkRead(e));

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.stormyTeal));
    }

    return RefreshIndicator(
      color: AppColors.stormyTeal,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.t('notifications'),
              subtitle: l10n.t('stayUpdated'),
              actions: [
                GKButton(
                  onPressed: hasReadable ? _markAllRead : null,
                  label: l10n.t('markAsRead'),
                  icon: Icons.done_all_rounded,
                  variant: GKButtonVariant.ghost,
                ),
              ],
            ),
            if (visible.isEmpty)
              GKCard(
                borderRadius: 28,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('noNotifications'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('noNotificationsHint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final n in visible) ...[
                _NotificationCard(
                  key: ValueKey(n.id),
                  event: n,
                  isFadingOut: _fadingOut.contains(n.id),
                  canMarkRead: _canMarkRead(n),
                  onMarkRead: () => _markSingleRead(n.id),
                  languageCode: l10n.languageCode,
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.event,
    required this.isFadingOut,
    required this.canMarkRead,
    required this.onMarkRead,
    required this.languageCode,
  });

  final GateEvent event;
  final bool isFadingOut;
  final bool canMarkRead;
  final VoidCallback onMarkRead;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final hasActiveWarning = event.hasLinkedAlert && !(event.linkedAlertResolved ?? false);
    final warningResolved = event.hasLinkedAlert && (event.linkedAlertResolved ?? false);

    //Colore icona warning: giallo se attivo, verde se risolto.
    final warningColor = warningResolved ? AppColors.success : AppColors.orangeGold;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isFadingOut ? 0.0 : 1.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: isFadingOut ? 0.95 : 1.0,
        child: GKCard(
          borderRadius: 28,
          padding: const EdgeInsets.all(18),
          borderColor: hasActiveWarning
              ? AppColors.orangeGold.withValues(alpha: 0.3)
              : warningResolved
                  ? AppColors.success.withValues(alpha: 0.2)
                  : null,
          background: hasActiveWarning
              ? AppColors.orangeGold.withValues(alpha: 0.05)
              : null,
          child: Row(
            children: [
              //Icona tipo evento.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.stormyTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _eventIcon(event.type),
                  color: AppColors.stormyTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.descriptionFor(languageCode),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        //Icona warning accanto al nome se c'è un alert collegato.
                        if (event.hasLinkedAlert) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: warningResolved
                                ? l10n.t('alertResolved')
                                : l10n.t('alertActive'),
                            child: Icon(
                              warningResolved
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded,
                              color: warningColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat.Hm().format(event.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _eventLabel(l10n, event.type),
                          style: TextStyle(
                            color: AppColors.stormyTeal.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              //Pulsante segna come letto (solo se canMarkRead).
              if (canMarkRead)
                Tooltip(
                  message: 'Segna come letto',
                  child: IconButton(
                    onPressed: onMarkRead,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    color: AppColors.stormyTeal,
                    iconSize: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _eventIcon(EventType type) {
    switch (type) {
      case EventType.entry:
        return Icons.login_rounded;
      case EventType.exit:
        return Icons.logout_rounded;
      case EventType.system:
        return Icons.info_rounded;
      case EventType.risk:
        return Icons.warning_amber_rounded;
    }
  }

  String _eventLabel(AppL10n l10n, EventType type) {
    switch (type) {
      case EventType.entry:
        return l10n.t('entry').toUpperCase();
      case EventType.exit:
        return l10n.t('exit').toUpperCase();
      case EventType.system:
        return 'SYSTEM';
      case EventType.risk:
        return 'RISK';
    }
  }
}
