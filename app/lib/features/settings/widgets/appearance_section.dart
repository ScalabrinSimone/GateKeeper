import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Schermata delle impostazioni di aspetto (tema + lingua).
///
/// Nota: questo file estende la schermata esistente con:
/// - toggle esplicito dark/light
/// - selettore lingua IT/EN
///
/// I widget di UI riutilizzano [ThemeProvider] e [LocaleProvider].
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsAppearanceTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // Tema
        Row(
          children: [
            Expanded(child: Text(l10n.settingsThemeLabel)),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.settingsThemeDark),
                  icon: const Icon(Icons.dark_mode_rounded),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.settingsThemeLight),
                  icon: const Icon(Icons.light_mode_rounded),
                ),
              ],
              selected: {themeProvider.isDark},
              onSelectionChanged: (values) {
                final value = values.first;
                context.read<ThemeProvider>().setDark(value);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Lingua
        Row(
          children: [
            Expanded(child: Text(l10n.settingsLanguageLabel)),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'it', label: const Text('Italiano')),
                ButtonSegment(value: 'en', label: const Text('English')),
              ],
              selected: {localeProvider.locale.languageCode},
              onSelectionChanged: (values) {
                final code = values.first;
                context
                    .read<LocaleProvider>()
                    .setLocale(Locale(code));
              },
            ),
          ],
        ),
      ],
    );
  }
}
