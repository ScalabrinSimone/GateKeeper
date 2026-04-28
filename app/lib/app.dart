import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget dell'app GateKeeper.
///
/// - [debugShowCheckedModeBanner] è false: rimuove il banner rosso "DEBUG" in alto a destra.
/// - [MaterialApp.router] usa go_router per la navigazione dichiarativa.
/// - La localizzazione IT/EN viene iniettata qui una sola volta.
class GateKeeperApp extends StatelessWidget {
  const GateKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GateKeeper',
      // Rimuove il banner DEBUG rosso in alto a destra
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      locale: const Locale('it'),
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
  }
}
