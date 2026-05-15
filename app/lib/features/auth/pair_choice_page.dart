import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/platform/platform_info.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/gk_button.dart';
import 'widgets/auth_scaffold.dart';

//Schermata di benvenuto: prima domanda chiara all'utente.
//
//Sono tre i percorsi possibili:
//  1. **Connetti la mia casa** → discovery / URL hub (LAN o tunnel) +
//     login se l'hub risulta già pairato.
//  2. **Configura un nuovo Raspberry** → scansione QR di pairing oppure
//     URL manuale, poi creazione admin. Disponibile solo da PC/mobile.
//  3. **Sono stato invitato** → incolla il token di un invito.
//
//Su web la (2) richiede comunque il discovery (UDP), perciò viene presentata
//come "configura via URL remoto" e l'utente può inserire la base URL.
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
          //Titolo guida: "Cosa vuoi fare?".
          Text(
            l10n.t('welcomePrompt'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),

          //Scelta primaria: connettiti a una casa esistente. Va anche bene
          //se l'utente vuole solo fare login: lo accompagniamo prima alla
          //discovery (LAN o URL remoto) per assicurarci che la baseUrl sia
          //valida, poi automaticamente apriamo /login se l'hub è pairato.
          _ChoiceCard(
            icon: Icons.home_rounded,
            color: AppColors.stormyTeal,
            title: l10n.t('connectExistingTitle'),
            description: l10n.t('connectExistingDescription'),
            actionLabel: l10n.t('connectExistingAction'),
            recommended: true,
            onTap: () {
              HapticFeedback.selectionClick();
              context.go('/onboarding/discover');
            },
          ),
          const SizedBox(height: 12),

          //Configura nuovo Raspberry: stessa pagina di discovery ma il
          //copy chiarisce che è per il primo setup.
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
          const SizedBox(height: 12),

          //Invito.
          _ChoiceCard(
            icon: Icons.mail_outline_rounded,
            color: AppColors.charcoalBlue,
            title: l10n.t('haveInviteTitle'),
            description: l10n.t('haveInviteDescription'),
            actionLabel: l10n.t('haveInvite'),
            onTap: () {
              HapticFeedback.selectionClick();
              context.go('/invite');
            },
          ),
        ],
      ),
      actionsBelow: Column(
        children: [
          //Scorciatoia per andare direttamente al login se l'utente è già
          //configurato. Mostriamo questo link più piccolo perché normalmente
          //il bootstrap automatico ci porta già al login.
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(l10n.t('alreadyConfigured')),
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.t('appName')} • v0.1',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
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
    this.recommended = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onTap;
  final bool recommended;

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (recommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppL10n.of(context).t('recommendedBadge'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
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
