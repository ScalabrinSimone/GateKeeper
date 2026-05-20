import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../shared/widgets/gk_button.dart';
import 'widgets/auth_quick_actions.dart';
import 'widgets/auth_scaffold.dart';

class PairChoicePage extends StatelessWidget {
  const PairChoicePage({super.key, required this.auth, required this.settings});

  final AuthController auth;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final isHomeConfigured = auth.hubInfo?.paired ?? false;

    return AuthScaffold(
      title: l10n.t('welcomeTitle'),
      subtitle: l10n.t('welcomeSubtitle'),
      trailing: AuthQuickActions(settings: settings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GKButton(
            onPressed: () => context.go('/onboarding/discover'),
            label: l10n.t('pairAction'),
            icon: Icons.router_rounded,
            expanded: true,
          ),
          const SizedBox(height: 16),
          GKButton(
            onPressed: isHomeConfigured ? () => context.go('/login') : null,
            label: l10n.t('connectExistingAction'),
            icon: Icons.login_rounded,
            variant: GKButtonVariant.secondary,
            expanded: true,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => context.go('/invite'),
            child: Text(l10n.t('haveInvite')),
          ),
        ],
      ),
      actionsBelow: Column(
        children: [
          Text(
            '${l10n.t('appName')} • v0.1',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
