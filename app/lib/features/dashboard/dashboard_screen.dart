import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/top_action_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/dashboard_stat_card.dart';
// PersonEntry è definita qui dentro person_status_card.dart — non ridichiarare!
import 'widgets/person_status_card.dart';
import 'widgets/presence_avatar.dart';
import 'widgets/recent_activity_card.dart';

/// Dashboard principale (Gateway Monitor).
///
/// Layout:
/// - Desktop: sidebar + contenuto a due colonne (activity | presenza)
/// - Mobile:  scroll verticale con cards e feed
///
/// TODO: sostituire i dati statici con stream dal backend FastAPI.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con titolo a sinistra + Alerts/profilo a destra
                PageHeader(
                  title: isMobile ? 'Dashboard' : 'Gateway Monitor',
                  trailing: const TopActionBar(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    0,
                    isMobile ? 16 : 24,
                    24,
                  ),
                  child: isMobile
                      ? const _MobileDashboardContent()
                      : const _DesktopDashboardContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------
class _DesktopDashboardContent extends StatelessWidget {
  const _DesktopDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Riga 4 stat-cards con altezza uniforme
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: DashboardStatCard(
                  label: 'Gateway Status',
                  value: 'Active',
                  subtitle: 'All sensors online',
                  icon: Icons.shield_outlined,
                  highlightColor: AppColors.success,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DashboardStatCard(
                  label: 'Users at Home',
                  value: '3',
                  subtitle: '2 away',
                  icon: Icons.home_outlined,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DashboardStatCard(
                  label: 'Tracked Objects Outside',
                  value: '4',
                  subtitle: 'Out with users',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DashboardStatCard(
                  label: 'Critical Alerts',
                  value: '1',
                  subtitle: 'Action Required',
                  icon: Icons.warning_amber_outlined,
                  highlightColor: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Riga activity (sinistra) + presenza (destra)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 3, child: _ActivityColumn()),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: const [
                  // Usiamo PersonEntry (pubblica, da person_status_card.dart)
                  PersonStatusCard(
                    title: 'Who is at Home',
                    people: [
                      PersonEntry(
                          name: 'Alice', role: 'Admin', isOnline: true),
                      PersonEntry(
                          name: 'Bob', role: 'Manager', isOnline: true),
                      PersonEntry(
                          name: 'Dave', role: 'Child', isOnline: true),
                    ],
                  ),
                  SizedBox(height: 20),
                  PersonStatusCard(
                    title: 'Who is Away',
                    people: [
                      PersonEntry(
                        name: 'Charlie',
                        role: 'Child',
                        subtitle: 'Left at 07:45 AM',
                        isOnline: false,
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Mobile layout
// ---------------------------------------------------------------------------
class _MobileDashboardContent extends StatelessWidget {
  const _MobileDashboardContent();

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
              PresenceAvatar(name: 'Alice', isOnline: true),
              SizedBox(width: 20),
              PresenceAvatar(name: 'Bob', isOnline: true),
              SizedBox(width: 20),
              PresenceAvatar(name: 'Dave', isOnline: true),
              SizedBox(width: 20),
              PresenceAvatar(name: 'Charlie', isOnline: false),
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
          childAspectRatio: 1.1,
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
              subtitle: 'Action Req.',
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
        const _ActivityColumn(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity column — condivisa desktop + mobile
// ---------------------------------------------------------------------------
class _ActivityColumn extends StatelessWidget {
  const _ActivityColumn();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: titolo a sinistra + badge LIVE a destra
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                const Text('Gateway Activity', style: AppTextStyles.sectionTitle),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.stormyTeal.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LiveDot(),
                      SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: AppColors.live,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: const [
                RecentActivityCard(
                  title: 'UNAUTHORIZED EXIT',
                  description:
                      'Object left the house without any authenticated user nearby.',
                  time: '10:45 AM',
                  objectName: 'MacBook Pro',
                  objectIcon: Icons.laptop_mac_outlined,
                  tags: ['Electronics', 'Office'],
                  icon: Icons.power_settings_new,
                  borderColor: AppColors.orange,
                  actionLabel: 'Mark as False Alarm',
                ),
                SizedBox(height: 14),
                RecentActivityCard(
                  title: 'Forgotten Item Alert',
                  description:
                      'Bob left the house but forgot an essential item.',
                  time: '09:15 AM',
                  objectName: 'Wallet',
                  objectIcon: Icons.wallet_outlined,
                  tags: ['Usually in Bedroom'],
                  icon: Icons.info_outline,
                  borderColor: AppColors.stormyTealBright,
                ),
                SizedBox(height: 14),
                RecentActivityCard(
                  title: 'Alice Arrived Home',
                  description: 'Entered with authenticated BLE node.',
                  time: '08:30 AM',
                  objectName: 'House Keys',
                  objectIcon: Icons.vpn_key_outlined,
                  tags: ['Backpack'],
                  icon: Icons.arrow_forward,
                  borderColor: Color(0xFF4A5568),
                  cardBackground: Color(0xFF252D3D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pallino LIVE pulsante
// ---------------------------------------------------------------------------

/// Pallino verde che pulsa per il badge LIVE nell'header di Gateway Activity.
///
/// Usa un [AnimationController] che ripete in loop (reverse: true),
/// animando l'opacità tra 0.3 e 1.0 ogni 1.2 secondi.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Fondamentale: smaltire il controller per non avere memory leak
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.live,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
