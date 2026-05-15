import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/platform/platform_info.dart';
import '../core/state/auth_controller.dart';
import '../core/state/settings_controller.dart';
import '../core/theme/app_colors.dart';
import '../features/account/account_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/pair_choice_page.dart';
import '../features/auth/recovery_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/events/events_page.dart';
import '../features/invite/invite_accept_page.dart';
import '../features/members/members_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/objects/objects_page.dart';
import '../features/onboarding/discovery_page.dart';
import '../features/onboarding/setup_wizard_page.dart';
import '../features/settings/settings_page.dart';
import '../shared/widgets/app_shell.dart';

//Costruisce il router principale dell'app.
//Le route di auth (login, pair, recovery, invite) stanno fuori dallo shell.
//Lo shell ospita le pagine principali a navigazione persistente.
//Il `redirect` regola il flusso a seconda dello stato di auth.
class AppRouter {
  AppRouter._();

  static GoRouter build({
    required SettingsController settings,
    required AuthController auth,
  }) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final stage = auth.stage;

        final isPublicRoute = loc == '/welcome' ||
            loc == '/login' ||
            loc == '/recover' ||
            loc.startsWith('/onboarding') ||
            loc.startsWith('/invite');

        if (stage == AuthStage.loading) {
          return loc == '/splash' ? null : '/splash';
        }
        if (stage == AuthStage.needsPairing) {
          //Hub non ancora configurato su questo dispositivo: invito al pairing.
          //Su Web l'utente non può fare il pairing (no UDP): lo lasciamo su
          ///welcome perché lì può inserire l'URL del tunnel manualmente.
          if (isPublicRoute) return null;
          return PlatformInfo.canPairDevice ? '/welcome' : '/welcome';
        }
        if (stage == AuthStage.offline) {
          if (isPublicRoute) return null;
          return '/welcome';
        }
        if (stage == AuthStage.needsLogin) {
          if (isPublicRoute) return null;
          return '/login';
        }
        //authenticated.
        if (loc == '/splash' || isPublicRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const _SplashPage()),
        GoRoute(path: '/welcome', builder: (_, __) => const PairChoicePage()),
        GoRoute(path: '/login', builder: (_, __) => LoginPage(auth: auth)),
        GoRoute(path: '/recover', builder: (_, __) => RecoveryPage(auth: auth)),
        GoRoute(
          path: '/onboarding/discover',
          builder: (_, __) => DiscoveryPage(auth: auth),
        ),
        GoRoute(
          path: '/onboarding/setup',
          builder: (_, s) => SetupWizardPage(
            auth: auth,
            //factory_code pre-popolato dopo scan QR / discovery.
            prefilledFactoryCode: s.uri.queryParameters['factory_code'],
          ),
        ),
        GoRoute(
          path: '/invite',
          builder: (_, __) => InviteAcceptPage(auth: auth),
        ),
        GoRoute(
          path: '/invite/:token',
          builder: (_, s) => InviteAcceptPage(auth: auth, token: s.pathParameters['token']),
        ),

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell, settings: settings, auth: auth),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: const DashboardPage(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/objects',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: const ObjectsPage(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/events',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: const EventsPage(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/members',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: const MembersPage(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/notifications',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: const NotificationsPage(),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: SettingsPage(settings: settings, auth: auth),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/account',
                pageBuilder: (context, state) => _buildPageWithFadeTransition(
                  context: context,
                  state: state,
                  child: AccountPage(auth: auth),
                ),
              ),
            ]),
          ],
        ),
      ],
    );
  }
}

CustomTransitionPage _buildPageWithFadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

//Splash + bootstrap. Si vede solo qualche istante.
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [AppColors.inkBlack, AppColors.charcoalBlue.withValues(alpha: 0.5)]
                : [const Color(0xFFF1F4F8), AppColors.stormyTeal.withValues(alpha: 0.08)],
          ),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GateKeeper',
              style: TextStyle(
                fontSize: 32,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: AppColors.stormyTeal,
              ),
            ),
            SizedBox(height: 22),
            CircularProgressIndicator(color: AppColors.stormyTeal),
          ],
        ),
      ),
    );
  }
}
