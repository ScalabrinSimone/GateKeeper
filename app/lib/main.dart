import 'package:flutter/material.dart';

import 'app.dart';
import 'core/state/settings_controller.dart';

//Entry point: inizializza il SettingsController, carica le preferenze persistite
//e avvia l'app con tema scuro come default (override solo se l'utente l'ha cambiato).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController();
  await settings.load();
  runApp(GateKeeperApp(settings: settings));
}
