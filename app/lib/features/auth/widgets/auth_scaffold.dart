import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gk_logo.dart';

//Scaffold condiviso dalle schermate di onboarding/auth.
//Centra il contenuto, mostra il logo e applica un background con accent teal.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxContentWidth = 460,
    this.actionsBelow,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double maxContentWidth;
  final Widget? actionsBelow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          //Background gradient sottile e cerchi decorativi.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.inkBlack,
                          AppColors.charcoalBlue.withValues(alpha: 0.4),
                        ]
                      : [
                          const Color(0xFFF1F4F8),
                          AppColors.stormyTeal.withValues(alpha: 0.08),
                        ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _Bubble(color: AppColors.stormyTeal.withValues(alpha: 0.18), size: 320),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _Bubble(color: AppColors.orangeGold.withValues(alpha: 0.10), size: 260),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: GKLogo(size: 64)),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.stormyTeal.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.stormyTeal.withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      if (actionsBelow != null) ...[
                        const SizedBox(height: 16),
                        actionsBelow!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}
