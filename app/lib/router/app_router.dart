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

/// Stato di autenticazione globale in memoria.
///
/// In produzione questo conterrà anche il JWT ricevuto da POST /api/auth/login
/// e sarà usato come header Authorization per tutte le chiamate API.
///
/// Ora è un singleton semplice in memoria — nessuna persistenza su disco
/// (SharedPreferences arriverà quando il backend sarà pronto).
///
/// Esempio d'uso:
/// ```dart
/// // Login riuscito:
/// AuthState.instance.setLoggedIn(true);
/// context.go('/dashboard');
///
/// // Sign out:
/// AuthState.instance.setLoggedIn(false);
/// context.go('/login');
/// ```
///
/// TODO: aggiungere campo `String? jwtToken` quando il backend è pronto.
/// TODO: persistere con flutter_secure_storage.
class AuthState {
  static final AuthState instance = AuthState._();
  AuthState._();

  // ─────────────────────────────────────────────────────────────────────────
  // TODO: per bypassare il login durante lo sviluppo, cambia a `true`.
  // Ricorda di reimpostare `false` prima di commit/demo!
  // ─────────────────────────────────────────────────────────────────────────
  bool isLoggedIn = false;

  /// Imposta lo stato di autenticazione.
  ///
  /// Parametri:
  /// - [value]: true = loggato, false = disconnesso
  ///
  /// Chiamare SEMPRE prima di context.go() per non triggerare il redirect.
  void setLoggedIn(bool value) => isLoggedIn = value;
}

/// Router centralizzato dell'app GateKeeper.
///
/// Struttura delle route:
/// ```
/// /login        → LoginScreen       (fuori ShellRoute)
/// /setup        → SetupScreen       (fuori ShellRoute)
/// /account      → AccountScreen     (fuori ShellRoute — slide-up)
/// /dashboard    → DashboardScreen   ┐
/// /users        → UsersScreen       │ dentro ShellRoute
/// /objects      → ObjectsScreen     │ (sidebar desktop / bottom nav mobile)
/// /events       → EventsScreen      │
/// /settings     → SettingsScreen    ┘
/// ```
///
/// Redirect globale:
/// - Non loggato → qualsiasi route protetta → /login
/// - Già loggato → /login o /setup → /dashboard
///
/// TODO: sostituire AuthState.isLoggedIn con verifica JWT reale.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',

    // ── Redirect globale di autenticazione ──────────────────────────────────
    // Valutato ad OGNI navigazione (context.go, context.push, browser back, ecc.).
    // Serve come guardia: anche se qualcuno bypassa la UI, non può accedere
    // alle route protette senza aver chiamato AuthState.setLoggedIn(true).
    redirect: (context, state) {
      final isLoggedIn = AuthState.instance.isLoggedIn;
      final path = state.uri.path;

      final publicPaths = ['/login', '/setup'];
      final isPublic = publicPaths.contains(path);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic) return '/dashboard';
      return null; // nessun redirect: lascia passare
    },

    routes: [
      // ── Route FUORI dallo ShellRoute (senza sidebar/bottom nav) ───────────

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
          // SlideUp + Fade: dà l'impressione di un drawer/sheet che sale
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

      // ── ShellRoute: sidebar + bottom nav ─────────────────────────────────
      // Tutte le route dentro questo ShellRoute sono "avvolte" da AppShell.
      // La sidebar rimane ferma; solo il contenuto centrale (child) cambia.
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            // NoTransitionPage: le route della shell non animano —
            // la sidebar resta ferma e il body si sostituisce istantaneamente.
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
