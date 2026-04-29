import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() async {
  // ensureInitialized() è obbligatorio se chiami metodi di piattaforma
  // (come SystemChrome o plugin nativi) prima di runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // ── Titlebar desktop ────────────────────────────────────────────────────
  // Su Windows/Linux/macOS Flutter mostra una titlebar nativa con il titolo
  // impostato in MaterialApp. Per nasconderla completamente si usa il package
  // window_manager (non ancora in pubspec.yaml).
  //
  // TODO: aggiungi window_manager al pubspec.yaml e sostituisci questo blocco:
  //
  //   import 'package:window_manager/window_manager.dart';
  //   await windowManager.ensureInitialized();
  //   await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  //
  // Per ora usiamo SystemChrome per rimuovere gli overlay di sistema su mobile
  // e impostiamo il titolo vuoto (vedi app.dart) per minimizzare la barra.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0D1117),
    ),
  );

  // TODO: inizializzare qui i servizi globali quando pronti:
  // - lettura config ambiente (dev/prod)
  // - flutter_secure_storage per il JWT
  // - dependency injection (get_it o riverpod)
  // - bootstrap ApiClient con baseUrl da config

  runApp(const GateKeeperApp());
}
