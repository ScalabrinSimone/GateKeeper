import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/events/events_screen.dart';
import '../features/objects/objects_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/users/users_screen.dart';

/// Router centralizzato dell'app GateKeeper.
///
/// Struttura delle route:
/// ```
/// /dashboard   → DashboardScreen
/// /users       → UsersScreen
/// /objects     → ObjectsScreen
/// /events      → EventsScreen
/// /settings    → SettingsScreen
/// ```
///
/// Tutte le route sono figlie di uno [ShellRoute] che:
/// - su desktop mostra la sidebar;
/// - su mobile mostra la bottom navigation bar.
///
/// TODO (Blocco 2B): aggiungere /login come route esterna allo ShellRoute,
/// con redirect automatico se il JWT è scaduto/assente.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    // Route di atterraggio al primo avvio
    // TODO (Blocco 2B): cambiare in '/login' e usare redirect per auth
    initialLocation: '/dashboard',
    routes: [
      // -------------------------------------------------------
      // ShellRoute: cornice comune (sidebar / bottom nav)
      // -------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          // AppShell decide da sola desktop vs mobile tramite LayoutBuilder
          return AppShell(child: child);
        },
        routes: [
          // 1. Dashboard — overview generale
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),

          // 2. Users & Roles — gestione membri e permessi
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersScreen(),
            ),
          ),

          // 3. RFID Objects — oggetti tracciati
          GoRoute(
            path: '/objects',
            name: 'objects',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ObjectsScreen(),
            ),
          ),

          // 4. Event Logs — storico eventi gateway
          GoRoute(
            path: '/events',
            name: 'events',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsScreen(),
            ),
          ),

          // 5. Settings — configurazione app e gateway
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      // TODO (Blocco 2B): aggiungere qui route /login e /setup
      // FUORI dallo ShellRoute per non avere sidebar/nav
    ],
  );
}
