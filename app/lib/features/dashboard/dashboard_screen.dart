import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/top_action_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/dashboard_stat_card.dart';
import 'widgets/person_status_card.dart';
import 'widgets/presence_avatar.dart';
import 'widgets/recent_activity_card.dart';

/// Dashboard iniziale.
///
/// Questa schermata replica la struttura principale del mockup:
/// - header con azioni utente
/// - cards overview
/// - activity feed
/// - persone in casa / fuori
///
/// TODO:
/// - collegare dati reali dal backend
/// - aggiungere popup notifiche/account
/// - animare cards e numeri
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    12,
                    isMobile ? 16 : 24,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (isMobile) const Expanded(child: SizedBox()),
                      const TopActionBar(),
                    ],
                  ),
                ),
                PageHeader(
                  title: isMobile ? 'Dashboard' : 'Gateway Monitor',
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    0,
                    isMobile ? 16 : 24,
                    24,
                  ),
                  child: isMobile
                      ? _MobileDashboardContent()
                      : _DesktopDashboardContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopDashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.55,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            DashboardStatCard(
              label: 'Gateway Status',
              value: 'Active',
              subtitle: 'All sensors online',
              icon: Icons.shield_outlined,
              highlightColor: AppColors.success,
            ),
            DashboardStatCard(
              label: 'Users at Home',
              value: '3',
              subtitle: '2 away',
              icon: Icons.home_outlined,
            ),
            DashboardStatCard(
              label: 'Tracked Objects Outside',
              value: '4',
              subtitle: 'Out with users',
              icon: Icons.inventory_2_outlined,
            ),
            DashboardStatCard(
              label: 'Critical Alerts',
              value: '1',
              subtitle: 'Action Required',
              icon: Icons.warning_amber_outlined,
              highlightColor: AppColors.orange,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 3,
              child: _ActivityColumn(),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: const [
                  PersonStatusCard(
                    title: 'Who is at Home',
                    people: ['Alice - Admin', 'Bob - Manager', 'Dave - Child'],
                  ),
                  SizedBox(height: 20),
                  PersonStatusCard(
                    title: 'Who is Away',
                    people: ['Charlie - Left at 07:45 AM'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileDashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRESENCE', style: AppTextStyles.label),
        const SizedBox(height: 16),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              PresenceAvatar(name: 'Alice'),
              SizedBox(width: 20),
              PresenceAvatar(name: 'Bob'),
              SizedBox(width: 20),
              PresenceAvatar(name: 'Dave'),
              SizedBox(width: 20),
              PresenceAvatar(name: 'Charlie'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text('SYSTEM OVERVIEW', style: AppTextStyles.label),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.08,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            DashboardStatCard(
              label: 'Gateway',
              value: 'Active',
              subtitle: 'All online',
              icon: Icons.shield_outlined,
              highlightColor: AppColors.success,
            ),
            DashboardStatCard(
              label: 'Alerts',
              value: '1',
              subtitle: 'Action Req',
              icon: Icons.warning_amber_outlined,
              highlightColor: AppColors.orange,
            ),
            DashboardStatCard(
              label: 'At Home',
              value: '3',
              subtitle: '2 away',
              icon: Icons.home_outlined,
            ),
            DashboardStatCard(
              label: 'Outdoors',
              value: '4',
              subtitle: 'With users',
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Text('RECENT ACTIVITY', style: AppTextStyles.label),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.stormyTeal.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Live',
                style: TextStyle(
                  color: AppColors.live,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _ActivityColumn(),
      ],
    );
  }
}

class _ActivityColumn extends StatelessWidget {
  const _ActivityColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        GlassCard(
          padding: EdgeInsets.all(0),
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gateway Activity',
                  style: AppTextStyles.sectionTitle,
                ),
                SizedBox(height: 18),
                RecentActivityCard(
                  title: 'UNAUTHORIZED EXIT',
                  description:
                      'Object left the house without any authenticated user nearby.',
                  time: '10:45 AM',
                  objectName: 'MacBook Pro',
                  tags: ['Electronics', 'Office'],
                  icon: Icons.power_settings_new,
                  borderColor: AppColors.orange,
                  actionLabel: 'Mark as False Alarm',
                ),
                SizedBox(height: 16),
                RecentActivityCard(
                  title: 'Forgotten Item Alert',
                  description:
                      'Bob left the house but forgot an essential item.',
                  time: '09:15 AM',
                  objectName: 'Wallet',
                  tags: ['Usually in Bedroom'],
                  icon: Icons.info_outline,
                  borderColor: AppColors.stormyTealBright,
                ),
                SizedBox(height: 16),
                RecentActivityCard(
                  title: 'Alice Arrived Home',
                  description: 'Entered with authenticated BLE node.',
                  time: '08:30 AM',
                  objectName: 'House Keys',
                  tags: ['Backpack'],
                  icon: Icons.arrow_forward,
                  borderColor: AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}