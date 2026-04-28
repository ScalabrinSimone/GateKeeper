import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: qui in futuro potrai inizializzare servizi globali:
  // - lettura config ambiente
  // - secure storage
  // - dependency injection
  // - bootstrap API client
  runApp(const GateKeeperApp());
}