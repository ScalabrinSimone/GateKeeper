import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';

//Pagina Dashboard: vista bento con stato, salute hub, membri, oggetti, eventi live.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final List<GateEvent> _events = List<GateEvent>.from(MockData.events);

  void _resolve(GateEvent event) {
    setState(() {
      event.resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final users = MockData.users;
    final objects = MockData.objects;

    final unresolved = _events.where((e) => e.isUnresolved).toList(growable: false);
    final isSecure = unresolved.isEmpty;
    final peopleInside = users.where((u) => u.isInside).length;
    final outsideObjects = objects.where((o) => !o.isInside).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.t('dashboard'),
                subtitle: '${l10n.t('address')} • ${l10n.t('systemSmooth')}',
                actions: [
                  _StatusBadge(isSecure: isSecure),
                  GKButton(
                    onPressed: () {},
                    label: l10n.t('addTag'),
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          child: _LiveEventsCard(events: _events, onResolve: _resolve),
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
                          child: _LiveEventsCard(events: _events, onResolve: _resolve),
                        ),
                      ],
                    ),
            ],
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
    const cpu = 0.42;

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
                  l10n.t('raspberryHub'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.memory_rounded, color: AppColors.stormyTeal),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.t('cpuTemp'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Text(
                '42°C',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cpu,
              minHeight: 6,
              backgroundColor: AppColors.stormyTeal.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.stormyTeal),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GKButton(
              onPressed: () {},
              label: l10n.t('logs'),
              icon: Icons.terminal_rounded,
              variant: GKButtonVariant.ghost,
              dense: true,
              expanded: true,
            ),
          ),
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

    return GKCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _MemberAvatar(user: users[i]),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: AppColors.stormyTeal.withValues(alpha: isInside ? 0.12 : 0.05),
              border: Border.all(
                color: isInside ? AppColors.stormyTeal : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isInside ? AppColors.stormyTeal : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.name.split(' ').first,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
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
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
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
              onPressed: () {},
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


