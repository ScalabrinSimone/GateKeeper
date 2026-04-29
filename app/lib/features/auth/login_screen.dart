import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptic_service.dart';
import '../../router/app_router.dart';
import '../../shared/widgets/gk_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Schermata di login.
///
/// È fuori dallo [ShellRoute] (sidebar/bottom nav non visibili).
/// Al successo del login viene impostato [AuthState.isLoggedIn] = true e
/// si naviga a '/dashboard'.
///
/// Flusso auth:
/// 1. App si avvia → router controlla isLoggedIn (false di default).
/// 2. Redirect automatico a '/login'.
/// 3. Utente inserisce credenziali → stub da 800ms simula risposta server.
/// 4. [AuthState.instance.setLoggedIn(true)] → [GoRouter] rivaluta il redirect
///    → go('/dashboard').
///
/// IMPORTANTE: la chiamata [context.go('/dashboard')] da sola NON basta.
/// Il router ha un redirect globale che controlla [AuthState.isLoggedIn]:
/// se rimane false, rimanda a /login. Per questo va impostato PRIMA del go().
///
/// TODO: implementare POST /api/auth/login reale.
/// TODO: salvare JWT in memoria (AuthState) e usarlo per tutte le API call.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Valida i campi prima di procedere
    if (!_formKey.currentState!.validate()) {
      await HapticService.error();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // TODO: chiamata reale:
    // try {
    //   final token = await ApiService.login(
    //     email: _emailCtrl.text,
    //     password: _passCtrl.text,
    //   );
    //   AuthState.instance.setLoggedIn(true, token: token);
    // } catch (e) {
    //   setState(() { _errorMessage = e.toString(); _loading = false; });
    //   return;
    // }

    // Stub: simula risposta server da 800ms
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // ─── FIX CRITICO ────────────────────────────────────────────────────────
    // Senza questa riga, il redirect globale del GoRouter reindirizza
    // a /login subito dopo context.go('/dashboard') perché isLoggedIn = false.
    // Va impostato PRIMA di navigare.
    AuthState.instance.setLoggedIn(true);
    // ────────────────────────────────────────────────────────────────────────

    await HapticService.success();
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo animato
                const _GkLogo(),
                const SizedBox(height: 8),
                const Text(
                  'GateKeeper',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Smart tag, safe exit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GkTextField(
                          label: 'Email',
                          hint: 'user@home.local',
                          controller: _emailCtrl,
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        GkTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passCtrl,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Password required'
                                  : null,
                        ),

                        // Errore inline (mostrato solo se presente)
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.stormyTeal,
                            foregroundColor: AppColors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => context.go('/setup'),
                  child: const Text(
                    'First time? Set up your home →',
                    style: TextStyle(
                        color: AppColors.stormyTealBright, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo GateKeeper con leggera animazione scale-in all'avvio.
class _GkLogo extends StatefulWidget {
  const _GkLogo();

  @override
  State<_GkLogo> createState() => _GkLogoState();
}

class _GkLogoState extends State<_GkLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    // Scale da 0.6 → 1.0 con overshoot leggero (elasticOut)
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.stormyTeal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.stormyTeal.withValues(alpha: 0.4)),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.stormyTealBright,
            size: 34,
          ),
        ),
      ),
    );
  }
}
