import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/state/settings_controller.dart';
import '../../../core/theme/app_colors.dart';

//Toolbar compatta con switch lingua (IT/EN) e tema (light/dark).
//Pensata per essere mostrata in alto a destra delle pagine di onboarding/
//login/setup: l'utente cambia preferenze prima ancora di avere un account.
class AuthQuickActions extends StatelessWidget {
  const AuthQuickActions({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangSwitch(settings: settings),
          const SizedBox(width: 8),
          _ThemeToggle(settings: settings),
        ],
      ),
    );
  }
}

//Selettore lingua a "pillole" IT / EN.
class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.settings});
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
          _chip(context, 'IT', settings.locale.languageCode == 'it',
              () => settings.setLocale(const Locale('it'))),
          _chip(context, 'EN', settings.locale.languageCode == 'en',
              () => settings.setLocale(const Locale('en'))),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
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
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

//Bottone toggle tema chiaro/scuro.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.settings});
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
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
