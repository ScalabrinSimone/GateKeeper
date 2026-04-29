import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget dell'app GateKeeper.
///
/// - [title] è impostato a stringa vuota: su desktop questo riduce al minimo
///   il testo mostrato nella titlebar nativa dell'OS.
///   Per nasconderla del tutto vedi il TODO in main.dart (window_manager).
/// - [debugShowCheckedModeBanner] = false: rimuove il banner rosso "DEBUG".
/// - [MaterialApp.router] usa go_router per la navigazione dichiarativa.
/// - La localizzazione IT/EN viene iniettata qui una sola volta per tutta l'app.
class GateKeeperApp extends StatelessWidget {
  const GateKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Titolo vuoto → la titlebar nativa non mostra testo.
      // TODO: con window_manager questo diventa irrilevante (titlebar nascosta).
      title: '',
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
