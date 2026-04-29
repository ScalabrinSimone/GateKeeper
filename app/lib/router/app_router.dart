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

  // Stub: utente sempre loggato per ora.
  // TODO: impostare a false e gestire il redirect a /login
  bool isLoggedIn = true;
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
/// TODO: quando il backend è pronto, sostituire _AuthState.isLoggedIn
/// con un controllo reale del JWT (validità, scadenza).
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    // Punto di partenza; il redirect qui sotto decide dove andare davvero
    initialLocation: '/dashboard',

    // ── Redirect globale di autenticazione ──────────────────────────────
    // Viene chiamato ad ogni navigazione. Se l'utente non è loggato,
    // viene mandato a /login (tranne se è già lì o su /setup).
    redirect: (context, state) {
      final isLoggedIn = _AuthState.instance.isLoggedIn;
      final path = state.uri.path;

      // Pagine accessibili senza login
      final publicPaths = ['/login', '/setup'];
      final isPublic = publicPaths.contains(path);

      if (!isLoggedIn && !isPublic) {
        // Non loggato → vai al login
        return '/login';
      }

      if (isLoggedIn && isPublic) {
        // Già loggato → non ha senso stare su /login o /setup
        return '/dashboard';
      }

      // Nessun redirect necessario
      return null;
    },

    routes: [
      // ── Route FUORI dallo ShellRoute ──────────────────────────────────
      // Queste route non hanno sidebar né bottom nav.

      GoRoute(
        path: '/login',
        name: 'login',
        // FadeTransition personalizzata (più morbida di NoTransition)
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

      // AccountScreen: fuori da Shell perché ha il proprio AppBar con back.
      GoRoute(
        path: '/account',
        name: 'account',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AccountScreen(),
          // Slide dal basso (feeling "modale")
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
