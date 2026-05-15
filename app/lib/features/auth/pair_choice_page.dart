import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/platform/platform_info.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/gk_button.dart';
import 'widgets/auth_scaffold.dart';

//Schermata mostrata quando l'hub non è (ancora) accoppiato a questa installazione.
//Lascia all'utente due strade: Login (se già ha credenziali su un hub raggiungibile)
//oppure Pair (configurazione iniziale di un nuovo Raspberry).
//Sul web la voce "Pair" è disabilitata: l'onboarding fisico richiede PC/mobile.
class PairChoicePage extends StatelessWidget {
  const PairChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final canPair = PlatformInfo.canPairDevice;

    return AuthScaffold(
      title: l10n.t('welcomeTitle'),
      subtitle: l10n.t('welcomeSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceCard(
            icon: Icons.login_rounded,
            color: AppColors.stormyTeal,
            title: l10n.t('signInTitle'),
            description: l10n.t('signInDescription'),
            actionLabel: l10n.t('signInAction'),
            onTap: () {
              HapticFeedback.selectionClick();
              context.go('/login');
            },
          ),
          const SizedBox(height: 14),
          _ChoiceCard(
            icon: Icons.router_rounded,
            color: canPair ? AppColors.orangeGold : theme.disabledColor,
            title: l10n.t('pairTitle'),
            description: canPair ? l10n.t('pairDescription') : l10n.t('pairWebHint'),
            actionLabel: l10n.t('pairAction'),
            onTap: canPair
                ? () {
                    HapticFeedback.selectionClick();
                    context.go('/onboarding/discover');
                  }
                : null,
          ),
          if (!canPair) ...[
            const SizedBox(height: 14),
            //Sul web non possiamo fare discovery, ma possiamo comunque
            //inserire un URL remoto (tunnel) per collegarci a un hub già
            //configurato altrove.
            _ChoiceCard(
              icon: Icons.cloud_outlined,
              color: AppColors.stormyTeal,
              title: l10n.t('remoteAccessTitle'),
              description: l10n.t('remoteAccessSubtitle'),
              actionLabel: l10n.t('connect'),
              onTap: () {
                HapticFeedback.selectionClick();
                context.go('/onboarding/discover');
              },
            ),
          ],
          const SizedBox(height: 18),
          //CTA secondaria: accetta un invito (incolla token / apri link).
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/invite'),
              icon: const Icon(Icons.qr_code_rounded, size: 18),
              label: Text(l10n.t('haveInvite')),
            ),
          ),
        ],
      ),
      actionsBelow: Center(
        child: Text(
          '${l10n.t('appName')} • v0.1',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GKButton(
                      onPressed: onTap,
                      label: actionLabel,
                      variant: GKButtonVariant.ghost,
                      dense: true,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
