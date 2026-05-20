import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/avatar_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import 'gk_logo.dart';

//Voce di navigazione laterale.
class _NavItem {
  const _NavItem({required this.labelKey, required this.icon, required this.path});

  final String labelKey;
  final IconData icon;
  final String path;
}

//Shell principale: sidebar desktop + header con quick actions + bottom nav mobile.
//Branches del router (indici):
// 0 = /dashboard
// 1 = /objects
// 2 = /events
// 3 = /members
// 4 = /notifications
// 5 = /alerts
// 6 = /settings
class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.settings,
    required this.auth,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final SettingsController settings;
  final AuthController auth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  //Elementi principali della sidebar e bottom nav.
  static const List<_NavItem> _mainItems = [
    _NavItem(labelKey: 'dashboard', icon: Icons.home_rounded, path: '/dashboard'),
    _NavItem(labelKey: 'objects', icon: Icons.inventory_2_rounded, path: '/objects'),
    _NavItem(labelKey: 'events', icon: Icons.history_rounded, path: '/events'),
    _NavItem(labelKey: 'members', icon: Icons.group_rounded, path: '/members'),
    _NavItem(labelKey: 'notifications', icon: Icons.notifications_rounded, path: '/notifications'),
    _NavItem(labelKey: 'settings', icon: Icons.settings_rounded, path: '/settings'),
  ];

  //Indice del branch "alerts" nel router.
  static const int _alertsBranchIndex = 5;

  @override
  void initState() {
    super.initState();
    //Carica avatar per l'utente corrente.
    final userId = widget.auth.user?.id.toString();
    if (userId != null) {
      AvatarController.instance.loadForUser(userId);
    }
    AvatarController.instance.addListener(_onAvatarChanged);
  }

  @override
  void dispose() {
    AvatarController.instance.removeListener(_onAvatarChanged);
    super.dispose();
  }

  void _onAvatarChanged() {
    if (mounted) setState(() {});
  }

  void _goBranch(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  //Converte l'indice dei _mainItems (0–5) all'indice del branch del router.
  //dashboard(0)->0, objects(1)->1, events(2)->2, members(3)->3,
  //notifications(4)->4, settings(5)->6.
  int _mainItemToRouterIndex(int mainIndex) {
    const map = [0, 1, 2, 3, 4, 6];
    if (mainIndex >= 0 && mainIndex < map.length) return map[mainIndex];
    return 0;
  }

  //Converte l'indice del branch del router all'indice dei _mainItems.
  //0->0, 1->1, 2->2, 3->3, 4->4, 5->alerts(non in main), 6->5.
  int _routerIndexToMainItem(int routerIndex) {
    const map = [0, 1, 2, 3, 4, -1, 5];
    if (routerIndex >= 0 && routerIndex < map.length) return map[routerIndex];
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 880;
    final l10n = AppL10n.of(context);
    final currentRouterIndex = widget.navigationShell.currentIndex;
    final currentMainIndex = _routerIndexToMainItem(currentRouterIndex);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              _Sidebar(
                items: _mainItems,
                currentMainIndex: currentMainIndex,
                isAlerts: currentRouterIndex == _alertsBranchIndex,
                onTapMain: (i) => _goBranch(_mainItemToRouterIndex(i)),
                onTapAlerts: () => _goBranch(_alertsBranchIndex),
                onAccount: () => context.go('/account'),
                settings: widget.settings,
                auth: widget.auth,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _titleForIndex(l10n, currentRouterIndex),
                    settings: widget.settings,
                    onAccount: () => context.go('/account'),
                    onNotifications: () => _goBranch(4),
                    onAlerts: () => _goBranch(_alertsBranchIndex),
                  ),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isCompact
          ? _BottomBar(
              items: _mainItems.take(5).toList(growable: false),
              currentIndex: currentMainIndex.clamp(0, 4),
              alertsSelected: currentRouterIndex == _alertsBranchIndex,
              onTap: (i) => _goBranch(_mainItemToRouterIndex(i)),
              onTapAlerts: () => _goBranch(_alertsBranchIndex),
            )
          : null,
    );
  }

  String _titleForIndex(AppL10n l10n, int routerIndex) {
    switch (routerIndex) {
      case 0: return l10n.t('dashboard');
      case 1: return l10n.t('objects');
      case 2: return l10n.t('events');
      case 3: return l10n.t('members');
      case 4: return l10n.t('notifications');
      case 5: return l10n.t('alerts');
      case 6: return l10n.t('settings');
      default: return 'GateKeeper';
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.currentMainIndex,
    required this.isAlerts,
    required this.onTapMain,
    required this.onTapAlerts,
    required this.onAccount,
    required this.settings,
    required this.auth,
  });

  final List<_NavItem> items;
  final int currentMainIndex;
  final bool isAlerts;
  final ValueChanged<int> onTapMain;
  final VoidCallback onTapAlerts;
  final VoidCallback onAccount;
  final SettingsController settings;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const GKLogo(size: 38),
              const SizedBox(width: 12),
              Text(
                'GateKeeper',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                return _SidebarItem(
                  icon: item.icon,
                  label: l10n.t(item.labelKey),
                  selected: index == currentMainIndex && !isAlerts,
                  onTap: () => onTapMain(index),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          //Area bottom-left: alerts (highlight arancione) + account.
          _SidebarItem(
            icon: Icons.notifications_active_rounded,
            label: l10n.t('alerts'),
            selected: isAlerts,
            onTap: onTapAlerts,
            highlight: true,
          ),
          const SizedBox(height: 6),
          _AccountTile(onTap: onAccount, settings: settings, auth: auth),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool highlight;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  bool _pressed = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    if (widget.selected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _SidebarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.highlight ? AppColors.orangeGold : AppColors.stormyTeal;

    final bg = (widget.selected || _pressed)
        ? accent.withValues(alpha: 0.18)
        : (_hover ? scheme.onSurface.withValues(alpha: 0.05) : Colors.transparent);

    final fg = (widget.selected || _pressed)
        ? accent
        : scheme.onSurface.withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (widget.selected)
                  BoxShadow(
                        color: accent.withValues(alpha: _glowAnimation.value * 0.28),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: child,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: widget.selected ? 4 : 0,
                height: 20,
                margin: EdgeInsets.only(right: widget.selected ? 10 : 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Icon(widget.icon, color: fg, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight:
                        widget.selected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.onTap,
    required this.settings,
    required this.auth,
  });

  final VoidCallback onTap;
  final SettingsController settings;
  final AuthController auth;

  String _initial(String? name) {
    final t = (name ?? '').trim();
    return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = auth.user;
    final name = user?.username ?? 'Guest';
    final subtitle = user?.role.toUpperCase() ?? AppL10n.of(context).t('account');
    final avatarPath = AvatarController.instance.avatarPath;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              //Avatar (immagine o iniziali).
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.stormyTeal, AppColors.charcoalBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildAvatarContent(avatarPath, name),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String? avatarPath, String name) {
    if (avatarPath != null && !kIsWeb) {
      return Image.file(
        File(avatarPath),
        fit: BoxFit.cover,
        width: 36,
        height: 36,
        errorBuilder: (_, __, ___) => _initialsWidget(name),
      );
    }
    return _initialsWidget(name);
  }

  Widget _initialsWidget(String name) {
    return Center(
      child: Text(
        _initial(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.settings,
    required this.onAccount,
    required this.onNotifications,
    required this.onAlerts,
  });

  final String title;
  final SettingsController settings;
  final VoidCallback onAccount;
  final VoidCallback onNotifications;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: AppColors.stormyTeal.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          _IconButtonGK(
            icon: Icons.notifications_active_rounded,
            tooltip: l10n.t('alerts'),
            badge: true,
            badgeColor: AppColors.orangeGold,
            onTap: onAlerts,
          ),
          const SizedBox(width: 8),
          _IconButtonGK(
            icon: Icons.notifications_rounded,
            tooltip: l10n.t('notifications'),
            onTap: onNotifications,
          ),
          const SizedBox(width: 8),
          _LanguageSwitcher(settings: settings),
          const SizedBox(width: 8),
          _ThemeButton(settings: settings),
          const SizedBox(width: 8),
          _IconButtonGK(
            icon: Icons.account_circle_rounded,
            tooltip: l10n.t('account'),
            onTap: onAccount,
          ),
        ],
      ),
    );
  }
}

class _IconButtonGK extends StatelessWidget {
  const _IconButtonGK({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = false,
    this.badgeColor = AppColors.orangeGold,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 20),
              if (badge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: _Dot(color: badgeColor),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langChip(context, 'IT', settings.locale.languageCode == 'it',
              () => settings.setLocale(const Locale('it'))),
          _langChip(context, 'EN', settings.locale.languageCode == 'en',
              () => settings.setLocale(const Locale('en'))),
        ],
      ),
    );
  }

  Widget _langChip(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.stormyTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = settings.isDark;
    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          settings.toggleTheme();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween<double>(begin: 0.85, end: 1).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Padding(
            key: ValueKey(isDark),
            padding: const EdgeInsets.all(10),
            child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20),
          ),
        ),
      ),
    );
  }
}

//Bottom bar mobile con feedback immediato al tap.
class _BottomBar extends StatefulWidget {
  const _BottomBar({
    required this.items,
    required this.currentIndex,
    required this.alertsSelected,
    required this.onTap,
    required this.onTapAlerts,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final bool alertsSelected;
  final ValueChanged<int> onTap;
  final VoidCallback onTapAlerts;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  int _pressedIndex = -1;
  bool _alertsPressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Item principali (prime 5).
              ...List.generate(widget.items.length, (i) {
                final selected = i == widget.currentIndex && !widget.alertsSelected;
                final pressed = i == _pressedIndex;
                final active = selected || pressed;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _pressedIndex = i);
                    },
                    onTapUp: (_) => setState(() => _pressedIndex = -1),
                    onTapCancel: () => setState(() => _pressedIndex = -1),
                    onTap: () => widget.onTap(i),
                    child: _BottomBarItem(
                      icon: widget.items[i].icon,
                      label: l10n.t(widget.items[i].labelKey),
                      active: active,
                      pressed: pressed,
                      accentColor: AppColors.stormyTeal,
                    ),
                  ),
                );
              }),
              //Item alerts (highlight arancione).
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _alertsPressed = true);
                  },
                  onTapUp: (_) => setState(() => _alertsPressed = false),
                  onTapCancel: () => setState(() => _alertsPressed = false),
                  onTap: widget.onTapAlerts,
                  child: _BottomBarItem(
                    icon: Icons.notifications_active_rounded,
                    label: l10n.t('alerts'),
                    active: widget.alertsSelected || _alertsPressed,
                    pressed: _alertsPressed,
                    accentColor: AppColors.orangeGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.pressed,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool pressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? accentColor.withValues(alpha: pressed ? 0.28 : 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: pressed ? 0.88 : 1.0,
            child: Icon(
              icon,
              size: 20,
              color: active
                  ? accentColor
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: active
                  ? accentColor
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
