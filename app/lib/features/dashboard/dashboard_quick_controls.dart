import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

/// Barra di controllo rapida mostrata nella Dashboard principale.
///
/// Contiene:
/// - Toggle dark/light theme
/// - Selettore rapido lingua IT/EN
/// - Slot opzionale per azioni aggiuntive (alert, user avatar ecc.)
class DashboardQuickControls extends StatelessWidget {
  const DashboardQuickControls({super.key, this.trailing});

  /// Widget opzionale mostrato a destra dei controlli (es. Alerts, avatar).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    // AppLocalizations.of(context) può restituire null se i delegati non sono
    // ancora inizializzati; qui usiamo "!" perché in MaterialApp.router
    // abbiamo registrato AppLocalizations.delegate.
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle tema dark / light
        Tooltip(
          message: themeProvider.isDark
              ? l10n.themeDarkLabel
              : l10n.themeLightLabel,
          child: IconButton(
            onPressed: () => context.read<ThemeProvider>().toggle(),
            icon: Icon(
              themeProvider.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Toggle rapido lingua IT/EN
        Tooltip(
          message: l10n.languageToggleTooltip,
          child: TextButton(
            onPressed: () => context.read<LocaleProvider>().toggle(),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              localeProvider.isItalian ? 'IT' : 'EN',
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
