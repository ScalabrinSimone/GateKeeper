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
/// Tiene traccia del login dell'utente durante la sessione.
/// In produzione qui ci sarà il JWT ricevuto da POST /api/auth/login.
///
/// Non usiamo SharedPreferences o flutter_secure_storage per ora perché
/// siamo ancora nella fase di mockup UI.
///
/// TODO: implementare persistenza JWT con flutter_secure_storage
/// quando il backend sarà pronto.
class _AuthState {
  static final _AuthState instance = _AuthState._();
  _AuthState._();

  // ─────────────────────────────────────────────────────────────────────────
  // TODO: per testare le schermate senza passare dal login ogni volta,
  // cambia questa riga da:   bool isLoggedIn = false;
  //                    a:    bool isLoggedIn = true;
  //
  // Ricorda di rimetterla a false prima di un demo/commit finale!
  // ─────────────────────────────────────────────────────────────────────────
  bool isLoggedIn = false;

  /// Imposta il flag di login (e in futuro salverà il token JWT).
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
/// /account      → AccountScreen     (fuori ShellRoute — slide-up)
/// /dashboard    → DashboardScreen   ┐
/// /users        → UsersScreen       │ dentro ShellRoute
/// /objects      → ObjectsScreen     │ (sidebar desktop / bottom nav mobile)
/// /events       → EventsScreen      │
/// /settings     → SettingsScreen    ┘
/// ```
///
/// Redirect automatico:
/// - se non loggato → /login
/// - se già loggato ma va a /login o /setup → /dashboard
///
/// TODO: sostituire _AuthState.isLoggedIn con verifica JWT reale.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',

    // ── Redirect globale di autenticazione ──────────────────────────────
    // Questo redirect viene valutato a ogni navigazione.
    // Se l'utente non è loggato e prova ad andare su una route protetta,
    // viene rimandato a /login automaticamente.
    redirect: (context, state) {
      final isLoggedIn = _AuthState.instance.isLoggedIn;
      final path = state.uri.path;

      final publicPaths = ['/login', '/setup'];
      final isPublic = publicPaths.contains(path);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic) return '/dashboard';
      return null; // nessun redirect: lascia passare
    },

    routes: [
      // ── Route FUORI dallo ShellRoute (senza sidebar/bottom nav) ───────

      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          // FadeTransition: più morbida di uno slide per la schermata di login
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

      // ── ShellRoute: sidebar + bottom nav ─────────────────────────────
      // Tutte le route dentro questo ShellRoute sono "avvolte" da AppShell,
      // che gestisce sidebar (desktop) e bottom navigation (mobile).
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            // NoTransitionPage: le route della shell non hanno animazione propria;
            // la sidebar rimane ferma e solo il contenuto centrale cambia.
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
