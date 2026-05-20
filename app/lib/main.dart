import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/state/auth_controller.dart';
import 'core/state/notifications_controller.dart';
import 'core/state/settings_controller.dart';

//Entry point: inizializza settings + notifiche + auth, poi avvia l'app.
//Il bootstrap di auth viene avviato in background: lo splash sta su finché
//il controller passa a uno stato definito.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController();
  await settings.load();

  //Notifiche locali: best-effort, se fallisce non blocca l'app.
  unawaited(NotificationsController.instance.initialize());

  final auth = AuthController();
  //Avvio del bootstrap senza await: il router mostra lo splash finché
  //AuthController è in stage 'loading', poi notifica.
  unawaited(auth.bootstrap());

  runApp(GateKeeperApp(settings: settings, auth: auth));
}
