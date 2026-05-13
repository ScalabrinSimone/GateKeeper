import 'package:go_router/go_router.dart';

import '../core/state/settings_controller.dart';
import '../features/account/account_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/events/events_page.dart';
import '../features/members/members_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/objects/objects_page.dart';
import '../features/settings/settings_page.dart';
import '../shared/widgets/app_shell.dart';

//Costruisce il router principale dell'app. Il SettingsController è passato
//al shell per esporre le quick actions (tema/lingua) nell'header.
class AppRouter {
  AppRouter._();

  static GoRouter build({required SettingsController settings}) {
    return GoRouter(
      initialLocation: '/dashboard',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell, settings: settings),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/objects', builder: (_, __) => const ObjectsPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/events', builder: (_, __) => const EventsPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/members', builder: (_, __) => const MembersPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/settings', builder: (_, __) => SettingsPage(settings: settings)),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/account', builder: (_, __) => const AccountPage()),
            ]),
          ],
        ),
      ],
    );
  }
}
