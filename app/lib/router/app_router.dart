import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/shell/app_shell.dart';

/// Router centralizzato dell'app.
///
/// Perché usare `go_router` qui:
/// - rotte dichiarative;
/// - desktop/web friendly;
/// - più semplice da scalare quando aggiungerai auth e deep links.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),

          // TODO: implementare davvero nei prossimi blocchi.
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Users & Roles'),
            ),
          ),
          GoRoute(
            path: '/objects',
            name: 'objects',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'RFID Objects'),
            ),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Event Logs'),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderPage(title: 'Settings'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title - coming in next block',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}