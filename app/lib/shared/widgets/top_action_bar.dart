import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/haptic_service.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// Dati stub degli alert
// ---------------------------------------------------------------------------

/// Singolo alert nel pannello notifiche.
///
/// Parametri:
/// - [icon]: icona del tipo di alert
/// - [title]: titolo breve
/// - [description]: dettaglio
/// - [time]: ora formattata
/// - [color]: colore indicatore
class _AlertItem {
  const _AlertItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;
}

/// TODO: rimpiazzare con stream da GET /api/events?type=alert dal backend.
const _stubAlerts = [
  _AlertItem(
    icon: Icons.power_settings_new,
    title: 'Unauthorized Exit',
    description: 'MacBook Pro uscito senza utente autenticato vicino.',
    time: '10:45 AM',
    color: AppColors.orange,
  ),
  _AlertItem(
    icon: Icons.child_care,
    title: 'Child Unaccompanied',
    description: 'Charlie uscito senza telefono rilevato nelle vicinanze.',
    time: '09:35 AM',
    color: AppColors.error,
  ),
];

// ---------------------------------------------------------------------------
// TopActionBar
// ---------------------------------------------------------------------------

/// Barra azioni in alto a destra della shell.
///
/// Contiene nell'ordine:
/// 1. [_ThemeToggleButton] — toggle rapido dark/light
/// 2. [_LanguageToggleButton] — toggle rapido IT/EN
/// 3. [_AlertsBadge] — badge con contatore alert + overlay panel
/// 4. [_UserMenuButton] — menu utente con account/settings/logout
///
/// I toggle di tema e lingua agiscono direttamente sui rispettivi provider;
/// le stesse impostazioni sono disponibili anche nella pagina Settings.
class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _ThemeToggleButton(),
        SizedBox(width: 6),
        _LanguageToggleButton(),
        SizedBox(width: 10),
        _AlertsBadge(),
        SizedBox(width: 10),
        _UserMenuButton(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle tema
// ---------------------------------------------------------------------------

/// Bottone icona che alterna dark ↔ light mode.
///
/// Mostra una luna in dark mode (indica che si può passare al chiaro)
/// e un sole in light mode (indica che si può passare allo scuro).
/// Questo è il pattern standard usato da GitHub, Figma, Linear.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    // context.watch ricostruisce il widget quando ThemeProvider notifica.
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: GestureDetector(
        onTap: () async {
          await HapticService.light();
          // context.read non ascolta — usato solo per chiamare metodi.
          context.read<ThemeProvider>().toggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.panelSoft,
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            // key diversa per forzare l'animazione al cambio
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              key: ValueKey(isDark),
              size: 17,
              color: isDark ? AppColors.orange : AppColors.stormyTealBright,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle lingua
// ---------------------------------------------------------------------------

/// Bottone che alterna la lingua dell'app tra Italiano e Inglese.
///
/// Mostra il codice della lingua corrente ("IT" o "EN").
/// Al tap chiama [LocaleProvider.toggle()] che notifica il [MaterialApp]
/// e aggiorna tutte le stringhe localizzate nell'app.
class _LanguageToggleButton extends StatelessWidget {
  const _LanguageToggleButton();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isItalian = localeProvider.isItalian;
    final currentLabel = isItalian ? 'IT' : 'EN';
    final nextLabel = isItalian ? 'EN' : 'IT';

    return Tooltip(
      message: 'Switch to $nextLabel',
      child: GestureDetector(
        onTap: () async {
          await HapticService.light();
          context.read<LocaleProvider>().toggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.panelSoft,
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              currentLabel,
              key: ValueKey(currentLabel),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge alerts con overlay panel
// ---------------------------------------------------------------------------

/// Badge "Alerts (N)" che al tap apre un overlay panel animato.
///
/// Usa [OverlayEntry] per mostrare il pannello senza bloccare la UI.
/// Il pannello si chiude toccando fuori oppure il pulsante X.
/// "View all" naviga alla pagina Event Logs.
class _AlertsBadge extends StatefulWidget {
  const _AlertsBadge();

  @override
  State<_AlertsBadge> createState() => _AlertsBadgeState();
}

class _AlertsBadgeState extends State<_AlertsBadge>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _closePanel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _openPanel() {
    if (_overlayEntry != null) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Salviamo il router context PRIMA di entrare nell'overlay,
    // così "View all" può navigare anche dall'OverlayEntry.
    final router = GoRouter.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePanel,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            right: 16,
            width: 340,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _AlertsPanel(
                  onClose: _closePanel,
                  // Passiamo il router per navigare dall'overlay
                  onViewAll: () {
                    _closePanel();
                    // Naviga agli event logs — il filtro alert può essere
                    // aggiunto come query param quando il backend è pronto.
                    // TODO: aggiungere ?filter=alert quando API è pronta
                    router.go('/events');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward();
  }

  Future<void> _closePanel() async {
    if (_overlayEntry == null) return;
    await _animCtrl.reverse();
    _overlayEntry!.remove();
    _overlayEntry = null;
    _animCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await HapticService.light();
        _overlayEntry == null ? _openPanel() : _closePanel();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          color: AppColors.panelSoft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 18,
              color: _stubAlerts.isNotEmpty
                  ? AppColors.orange
                  : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Alerts (${_stubAlerts.length})',
              style: TextStyle(
                color: _stubAlerts.isNotEmpty
                    ? AppColors.orange
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pannello lista alert
// ---------------------------------------------------------------------------

/// Pannello overlay con la lista degli alert attivi.
///
/// Parametri:
/// - [onClose]: chiude il pannello
/// - [onViewAll]: naviga alla pagina Event Logs e chiude il pannello
class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({
    required this.onClose,
    required this.onViewAll,
  });

  final VoidCallback onClose;
  final VoidCallback onViewAll; // FIX: navigazione "View all" funzionante

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  const Text(
                    'Active Alerts',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_stubAlerts.length}',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            // Lista alert
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stubAlerts.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, i) {
                final alert = _stubAlerts[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: alert.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(alert.icon, color: alert.color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(alert.time, style: AppTextStyles.label),
                    ],
                  ),
                );
              },
            ),
            // Footer "View all" — ora naviga davvero
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: onViewAll, // FIX: usa onViewAll invece di stub vuoto
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'View all in Event Logs',
                      style: TextStyle(
                        color: AppColors.stormyTealBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.stormyTealBright,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dropdown menu utente
// ---------------------------------------------------------------------------

/// Bottone avatar+nome con menu a tendina.
///
/// Voci:
/// - My Account → push('/account')
/// - Notification Settings → push('/settings')
/// - Sign Out → dialog conferma → go('/login')
class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton();

  static const _itemAccount       = 'account';
  static const _itemNotifications = 'notifications';
  static const _itemSignOut       = 'signout';

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await HapticService.heavy();
      AuthState.instance.setLoggedIn(false);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 42),
      onSelected: (value) async {
        switch (value) {
          case _itemAccount:
            await HapticService.light();
            if (context.mounted) context.push('/account');
          case _itemNotifications:
            await HapticService.light();
            if (context.mounted) context.push('/settings');
          case _itemSignOut:
            await _handleSignOut(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.panelSoft,
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.orange,
              child: Icon(Icons.person, size: 14, color: AppColors.inkBlack),
            ),
            SizedBox(width: 6),
            Text(
              'Alice',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: _itemAccount,
          child: Row(children: [
            Icon(Icons.person_outline, size: 17, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('My Account', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ]),
        ),
        const PopupMenuItem<String>(
          value: _itemNotifications,
          child: Row(children: [
            Icon(Icons.notifications_none, size: 17, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('Notification Settings', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _itemSignOut,
          child: Row(children: [
            Icon(Icons.logout, size: 17, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(color: AppColors.error, fontSize: 14)),
          ]),
        ),
      ],
    );
  }
}
