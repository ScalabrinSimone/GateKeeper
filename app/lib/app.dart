import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget dell'app GateKeeper.
///
/// Struttura:
/// ```
/// MultiProvider   ← inietta ThemeProvider e LocaleProvider
///   └─ _AppView  ← Consumer2 che reagisce ai cambi di tema/lingua
///        └─ MaterialApp.router
/// ```
///
/// Separare [GateKeeperApp] (che crea i provider) da [_AppView] (che li
/// consuma) è il pattern standard con provider: evita che il MultiProvider
/// stesso si ricostruisca quando i provider notificano.
class GateKeeperApp extends StatelessWidget {
  const GateKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider registra più ChangeNotifier in una sola volta.
    // L'ordine non conta (non ci sono dipendenze tra i due provider).
    return MultiProvider(
      providers: [
        // Gestisce dark / light mode
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Gestisce la lingua (it / en)
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const _AppView(),
    );
  }
}

/// Widget che consuma [ThemeProvider] e [LocaleProvider] e costruisce
/// il [MaterialApp.router] con i valori correnti.
///
/// [Consumer2] ascolta entrambi i provider e si ricostruisce solo quando
/// uno dei due notifica un cambiamento — non alla ogni rebuild del parent.
class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    // consumer2 = ascolta due provider contemporaneamente
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp.router(
          title: '',
          debugShowCheckedModeBanner: false,

          // Tema: dark o light in base al provider
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

          // Router declarativo go_router
          routerConfig: AppRouter.router,

          // Lingua corrente dal provider
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('it'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
