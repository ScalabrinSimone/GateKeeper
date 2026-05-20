import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/api_config.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/dto.dart';
import '../../data/services/realtime_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';
import '../objects/widgets/object_form_sheet.dart';

//Pagina Dashboard: ascolta RealtimeService che aggiorna i dati in background.
//Quando RealtimeService notifica un cambiamento, la dashboard si rirenderizza
//automaticamente tramite ListenableBuilder senza richieste esplicite.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RealtimeService.instance,
      builder: (context, _) => _DashboardView(
        rt: RealtimeService.instance,
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView({required this.rt});
  final RealtimeService rt;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  RealtimeService get rt => widget.rt;

  bool get _canManageDevices {
    final u = AuthController.instance.user;
    if (u == null) return false;
    if (u.role == 'admin') return true;
    return u.permissions[GKPermissions.canManageDevices] == true;
  }

  Future<void> _openCreateObject(BuildContext context) async {
    final l10n = AppL10n.of(context);
    final res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ObjectFormSheet(),
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('objectCreated'))),
      );
      await rt.refresh();
    }
  }

  void _resolve(GateEvent event) {
    setState(() => event.resolved = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final events = rt.events;
    final users = rt.users;
    final objects = rt.objects;
    final loading = !rt.isRunning && events.isEmpty && users.isEmpty;

    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.stormyTeal));
    }

    final unresolved = events.where((e) => e.isUnresolved).toList(growable: false);
    final isSecure = unresolved.isEmpty;
    final currentUserId = AuthController.instance.user?.id.toString();
    final peopleInside = users.where((u) {
      if (u.isInside) return true;
      return currentUserId != null && u.id == currentUserId;
    }).length;
    final outsideObjects = objects.where((o) => !o.isInside).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;
        return RefreshIndicator(
          color: AppColors.stormyTeal,
          onRefresh: rt.refresh,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.t('dashboard'),
                subtitle: AuthController.instance.hubInfo?.houseName != null
                    ? '${AuthController.instance.hubInfo!.houseName} • ${l10n.t('systemSmooth')}'
                    : l10n.t('systemSmooth'),
                actions: [
                  _StatusBadge(isSecure: isSecure),
                  if (_canManageDevices)
                    GKButton(
                      onPressed: () => _openCreateObject(context),
                      label: l10n.t('addObject'),
                      icon: Icons.add_rounded,
                      variant: GKButtonVariant.secondary,
                    ),
                ],
              ),
              //Grid bento principale.
              wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _StatusBlock(
                                      isSecure: isSecure,
                                      unresolved: unresolved.length,
                                      peopleInside: peopleInside,
                                      outsideObjects: outsideObjects,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: _HubCard()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _MembersStrip(users: users)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _ObjectsMini(objects: objects.take(4).toList())),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _LiveEventsCard(events: events, onResolve: _resolve),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _StatusBlock(
                          isSecure: isSecure,
                          unresolved: unresolved.length,
                          peopleInside: peopleInside,
                          outsideObjects: outsideObjects,
                        ),
                        const SizedBox(height: 16),
                        _HubCard(),
                        const SizedBox(height: 16),
                        _MembersStrip(users: users),
                        const SizedBox(height: 16),
                        _ObjectsMini(objects: objects.take(4).toList()),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 520,
                          child: _LiveEventsCard(events: events, onResolve: _resolve),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isSecure});
  final bool isSecure;
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return StatusPill(
      label: isSecure ? l10n.t('statusActive') : l10n.t('statusWarning'),
      color: isSecure ? AppColors.stormyTeal : AppColors.orangeGold,
      icon: isSecure ? Icons.shield_rounded : Icons.warning_amber_rounded,
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.isSecure,
    required this.unresolved,
    required this.peopleInside,
    required this.outsideObjects,
  });

  final bool isSecure;
  final int unresolved;
  final int peopleInside;
  final int outsideObjects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final color = isSecure ? AppColors.stormyTeal : AppColors.orangeGold;

    return GKCard(
      borderRadius: 36,
      padding: const EdgeInsets.fromLTRB(28, 28, 24, 28),
      borderColor: color.withValues(alpha: 0.35),
      elevated: !isSecure,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSecure ? l10n.t('allSecure') : l10n.t('hazardsDetected'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSecure ? l10n.t('allSecure') : '$unresolved ${l10n.t('unresolvedAlerts')}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$peopleInside ${l10n.t('usersInside')} • $outsideObjects ${l10n.t('objectsOutsideCount')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isSecure ? Icons.shield_rounded : Icons.warning_amber_rounded,
              size: 48,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final hub = AuthController.instance.hubInfo;
    final houseName = hub?.houseName ?? l10n.t('raspberryHub');
    final apiVersion = hub?.apiVersion;
    final baseUrl = ApiConfig.baseUrl;

    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  houseName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.memory_rounded, color: AppColors.stormyTeal),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  baseUrl ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          if (apiVersion != null) ...[
            const SizedBox(height: 8),
            Text(
              'API v$apiVersion',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class _MembersStrip extends StatelessWidget {
  const _MembersStrip({required this.users});
  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    //Online significa "loggato/connesso": fintanto che il sistema BLE non
    //popola `current_location`, consideriamo online l'utente attualmente
    //loggato in questo dispositivo. È un'approssimazione utile lato UI,
    //e verrà rimpiazzata dal segnale BLE non appena disponibile.
    final currentUserId = AuthController.instance.user?.id.toString();
    final augmented = users.map((u) {
      final isMe = currentUserId != null && u.id == currentUserId;
      if (u.isInside || !isMe) return u;
      return AppUser(
        id: u.id,
        name: u.name,
        role: u.role,
        isInside: true,
        lastSeenAt: u.lastSeenAt,
        avatarUrl: u.avatarUrl,
        isActive: u.isActive,
        currentLocation: u.currentLocation,
        email: u.email,
        permissions: u.permissions,
      );
    }).toList(growable: false);

    //Ordina: online prima (da sinistra), offline dopo in grigio.
    final sorted = [...augmented]..sort((a, b) {
        if (a.isInside == b.isInside) return 0;
        return a.isInside ? -1 : 1;
      });

    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.t('members').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 8),
              //Contatore utenti online.
              if (sorted.any((u) => u.isInside))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.stormyTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sorted.where((u) => u.isInside).length} online',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.stormyTeal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: sorted.isEmpty
                ? Center(
                    child: Text(
                      l10n.t('noMembers'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => _MemberAvatar(user: sorted[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isInside = user.isInside;
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isInside
                      ? AppColors.stormyTeal.withValues(alpha: 0.12)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isInside
                        ? AppColors.stormyTeal.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: isInside ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isInside
                        ? AppColors.stormyTeal
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
              //Pallino verde luminoso per utenti online, grigio per offline.
              Positioned(
                bottom: -2,
                right: -2,
                child: _OnlineDot(isOnline: isInside),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            user.name.split(' ').first,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: isInside
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

//Pallino di stato con alone luminoso per utenti online.
class _OnlineDot extends StatefulWidget {
  const _OnlineDot({required this.isOnline});
  final bool isOnline;
  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isOnline) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _OnlineDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline ? AppColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    if (!widget.isOnline) {
      //Pallino grigio statico per offline.
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).cardColor, width: 2),
        ),
      );
    }
    //Pallino verde con alone pulsante per online.
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          //Alone esterno pulsante.
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.3 * _pulse.value),
              shape: BoxShape.circle,
            ),
          ),
          //Pallino centrale.
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).cardColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.6 * _pulse.value),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectsMini extends StatelessWidget {
  const _ObjectsMini({required this.objects});
  final List objects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('objects').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          //Empty state: niente box vuoto, mostro un'unica riga di hint.
          if (objects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.t('noObjects'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final o in objects)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ObjectRow(name: o.name, tag: o.rfidTag, icon: o.icon, isInside: o.isInside),
              ),
        ],
      ),
    );
  }
}

class _ObjectRow extends StatelessWidget {
  const _ObjectRow({required this.name, required this.tag, required this.icon, required this.isInside});
  final String name;
  final String tag;
  final IconData icon;
  final bool isInside;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isInside ? AppColors.stormyTeal : AppColors.orangeGold;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(
                  'Tag: $tag',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: isInside ? 'IN' : 'OUT', color: color, dense: true),
        ],
      ),
    );
  }
}

class _LiveEventsCard extends StatelessWidget {
  const _LiveEventsCard({required this.events, required this.onResolve});
  final List<GateEvent> events;
  final void Function(GateEvent event) onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final df = DateFormat.Hm();

    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('liveEvents'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const _BlinkingDot(),
              const SizedBox(width: 6),
              Text(
                l10n.t('live'),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          //Empty state: niente lista scrollabile vuota.
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.t('noEvents'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
          //ConstrainedBox invece di Expanded: evita RenderBox unbounded
          //quando il card è dentro SingleChildScrollView (wide layout).
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final event = events[i];
                final critical = event.isCritical;
                final accent = critical ? AppColors.orangeGold : AppColors.stormyTeal;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: event.resolved == true ? 0.45 : 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: critical && event.resolved != true
                          ? AppColors.orangeGold.withValues(alpha: 0.10)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: critical && event.resolved != true
                            ? AppColors.orangeGold.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                critical ? Icons.warning_amber_rounded : Icons.access_time_rounded,
                                color: critical ? AppColors.inkBlack : Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    event.descriptionFor(l10n.languageCode),
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    df.format(event.timestamp),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (critical && event.resolved != true) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: GKButton(
                              onPressed: () => onResolve(event),
                              icon: Icons.check_circle_rounded,
                              label: l10n.t('markResolved'),
                              variant: GKButtonVariant.secondary,
                              dense: true,
                              expanded: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GKButton(
              onPressed: () => context.go('/events'),
              label: l10n.t('fullHistory'),
              variant: GKButtonVariant.outline,
              dense: true,
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.orangeGold.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}


