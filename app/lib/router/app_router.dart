import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/setup_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/events/events_screen.dart';
import '../features/objects/objects_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/users/users_screen.dart';

/// Stato di autenticazione in memoria.
///
/// In produzione questo conterrà il JWT ricevuto da POST /api/auth/login.
/// Non usiamo SharedPreferences o localStorage perché l'app non ne ha
/// bisogno per questo prototype (il token scade a ogni riavvio).
///
/// TODO: implementare AuthState.instance con token persistente
/// usando flutter_secure_storage quando il backend sarà pronto.
class _AuthState {
  static final _AuthState instance = _AuthState._();
  _AuthState._();

  // Stub: false = l'app parte dal login (corretto per lo sviluppo UI).
  // TODO: leggere da flutter_secure_storage per ricordare la sessione.
  bool isLoggedIn = false;

  /// Imposta il flag di login e il token JWT.
  ///
  /// Chiamare dopo un login riuscito:
  /// ```dart
  /// _AuthState.instance.setLoggedIn(true);
  /// context.go('/dashboard');
  /// ```
  void setLoggedIn(bool value) => isLoggedIn = value;
}

/// Router centralizzato dell'app GateKeeper.
///
/// Struttura delle route:
/// ```
/// /login        → LoginScreen       (fuori ShellRoute)
/// /setup        → SetupScreen       (fuori ShellRoute)
/// /account      → AccountScreen     (fuori ShellRoute)
/// /dashboard    → DashboardScreen   ┐
/// /users        → UsersScreen       │ dentro ShellRoute
/// /objects      → ObjectsScreen     │ (sidebar + bottom nav)
/// /events       → EventsScreen      │
/// /settings     → SettingsScreen    ┘
/// ```
///
/// Redirect automatico:
/// - se non loggato → /login
/// - se loggato ma va a /login o /setup → /dashboard
///
/// TODO: sostituire _AuthState.isLoggedIn con verifica JWT reale.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    // Punto di partenza; il redirect qui sotto decide dove andare davvero
    initialLocation: '/dashboard',

    // ── Redirect globale di autenticazione ──────────────────────────────
    redirect: (context, state) {
      final isLoggedIn = _AuthState.instance.isLoggedIn;
      final path = state.uri.path;

      final publicPaths = ['/login', '/setup'];
      final isPublic = publicPaths.contains(path);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic) return '/dashboard';
      return null;
    },

    routes: [
      // ── Route FUORI dallo ShellRoute ──────────────────────────────────

      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      GoRoute(
        path: '/setup',
        name: 'setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SetupScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      GoRoute(
        path: '/account',
        name: 'account',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AccountScreen(),
          transitionsBuilder: (context, animation, _, child) {
            final tween = Tween(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      // ── ShellRoute: sidebar + bottom nav ─────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsersScreen()),
          ),
          GoRoute(
            path: '/objects',
            name: 'objects',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ObjectsScreen()),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EventsScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}
