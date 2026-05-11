import 'package:flutter/material.dart';

import '../../core/constants/app_breakpoints.dart';
import 'desktop_sidebar.dart';
import 'mobile_bottom_nav.dart';

/// Shell responsiva comune.
///
/// Questa è la "cornice" di tutte le pagine dell'app:
/// - **desktop**: sidebar fissa a sinistra + area contenuto a destra
/// - **mobile**: bottom navigation bar in basso
///
/// # Correzione bug dark/light mode
/// Il bug per cui in light mode solo le card cambiavano colore (lo sfondo
/// e la sidebar rimanevano scuri) era causato da:
/// - `backgroundColor: AppColors.inkBlack` hardcoded nello [Scaffold]
/// - gradiente `LinearGradient` hardcoded nel [Container] body
///
/// La correzione usa `Theme.of(context).colorScheme.surface` che si aggiorna
/// automaticamente quando [ThemeProvider] commuta dark ↔ light.
///
/// Il gradiente di sfondo è preservato **solo in dark mode** per mantenere
/// l'identità visiva del mockup Figma originale.
///
/// TODO: aggiungere transizione animata al cambio layout mobile ↔ desktop.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Theme.of(context) si aggiorna automaticamente perché MaterialApp.router
    // in app.dart ascolta ThemeProvider tramite Consumer2.
    // NOTA: non usare const qui — i colori devono essere letti a runtime.
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.mobile;

        return Scaffold(
          // PRIMA (bug): AppColors.inkBlack hardcoded → sempre scuro
          // ORA (fix):   colorScheme.surface → si aggiorna con il tema
          backgroundColor: colorScheme.surface,
          bottomNavigationBar: isDesktop ? null : const MobileBottomNav(),
          body: Container(
            decoration: isDark
                // Dark mode: gradiente del mockup originale (invariato)
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF121826), Color(0xFF0D1117)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  )
                // Light mode: colore piatto dal tema, nessun gradiente scuro
                : BoxDecoration(color: colorScheme.surface),
            child: Row(
              children: [
                if (isDesktop) const DesktopSidebar(),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}
