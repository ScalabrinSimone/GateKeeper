import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget dell'app.
///
/// Qui configuriamo:
/// - tema globale
/// - router centrale
/// - localizzazione IT/EN
///
/// Tenerlo separato da `main.dart` è comodo perché:
/// - `main.dart` resta pulito;
/// - nei test puoi montare direttamente `GateKeeperApp`.
class GateKeeperApp extends StatelessWidget {
  const GateKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GateKeeper',
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