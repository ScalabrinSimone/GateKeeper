import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() async {
  // ensureInitialized() è obbligatorio se chiami metodi di piattaforma
  // (come SystemChrome o plugin nativi) prima di runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // ── Titlebar desktop ────────────────────────────────────────────────────
  // Su Windows/Linux/macOS Flutter mostra una titlebar nativa.
  // Per nasconderla si usa window_manager (non ancora in pubspec.yaml).
  //
  // TODO: aggiungi window_manager al pubspec.yaml e sostituisci con:
  //   import 'package:window_manager/window_manager.dart';
  //   await windowManager.ensureInitialized();
  //   await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0D1117),
    ),
  );

  // TODO: inizializzare qui i servizi globali quando pronti:
  // - lettura config ambiente (dev/prod)
  // - flutter_secure_storage per il JWT
  // - bootstrap ApiClient con baseUrl da config

  // GateKeeperApp crea i provider (ThemeProvider, LocaleProvider)
  // e li inietta nell'albero dei widget tramite MultiProvider.
  runApp(const GateKeeperApp());
}
