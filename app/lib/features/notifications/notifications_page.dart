import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/data/mock_data.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/widgets/gk_button.dart';
import '../../shared/widgets/gk_card.dart';
import '../../shared/widgets/section_header.dart';

//Centro notifiche: filtra gli eventi critici e li mostra come avvisi.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final items = MockData.events.where((e) => e.severity == EventSeverity.critical).toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.t('notifications'),
            subtitle: l10n.t('stayUpdated'),
            actions: [
              GKButton(
                onPressed: () {},
                label: l10n.t('markAsRead'),
                icon: Icons.done_all_rounded,
                variant: GKButtonVariant.ghost,
              ),
            ],
          ),
          if (items.isEmpty)
            GKCard(
              borderRadius: 28,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.notifications_off_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.t('noNotifications'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
            for (final n in items) ...[
              _NotificationCard(event: n),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.event});
  final GateEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final critical = event.severity == EventSeverity.critical;
    final color = critical ? AppColors.orangeGold : AppColors.stormyTeal;

    return GKCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(20),
      background: critical ? AppColors.orangeGold.withValues(alpha: 0.06) : null,
      borderColor: critical ? AppColors.orangeGold.withValues(alpha: 0.25) : null,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: critical ? AppColors.orangeGold : AppColors.stormyTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(
              critical ? Icons.warning_amber_rounded : Icons.info_rounded,
              color: critical ? AppColors.inkBlack : AppColors.stormyTeal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.descriptionFor(l10n.languageCode),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
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
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      critical ? 'RISK' : 'INFO',
                      style: TextStyle(color: color, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
