import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptic_service.dart';
import '../../shared/widgets/gk_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Schermata di login.
///
/// È fuori dallo [ShellRoute] (sidebar/bottom nav non visibili).
/// L'utente inserisce email e password; al successo viene
/// rediretto a '/dashboard'.
///
/// Flusso auth:
/// 1. App si avvia → router controlla se c'è un JWT valido in memoria;
/// 2. Se no → redirect a '/login';
/// 3. Login → POST /api/auth/login → riceve JWT;
/// 4. JWT salvato in memoria → redirect a '/dashboard'.
///
/// TODO: implementare POST /api/auth/login
/// TODO: salvare JWT (in memoria, non localStorage/SharedPreferences
///        per ora) e passarlo a tutte le API call successive.
/// TODO: bottone "First time? Set up your home" → '/setup'
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
    if (!_formKey.currentState!.validate()) {
      await HapticService.error();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // TODO: chiamata reale
    // try {
    //   final token = await ApiService.login(
    //     email: _emailCtrl.text,
    //     password: _passCtrl.text,
    //   );
    //   AuthState.instance.setToken(token);
    //   if (mounted) context.go('/dashboard');
    // } catch (e) {
    //   setState(() => _errorMessage = 'Invalid credentials');
    // }

    // Stub: simula login riuscito dopo 800ms
    await Future<void>.delayed(const Duration(milliseconds: 800));
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
            // Larghezza massima del form su desktop
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo + titolo
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

                // Form
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
                        const SizedBox(height: 8),

                        // Messaggio errore
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.stormyTeal,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Link primo setup
                TextButton(
                  onPressed: () => context.go('/setup'),
                  child: const Text(
                    'First time? Set up your home →',
                    style: TextStyle(
                      color: AppColors.stormyTealBright,
                      fontSize: 13,
                    ),
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

/// Logo SVG minimalista di GateKeeper (scudo + tag).
class _GkLogo extends StatelessWidget {
  const _GkLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.stormyTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.stormyTeal.withValues(alpha: 0.4),
          ),
        ),
        child: const Icon(
          Icons.shield_outlined,
          color: AppColors.stormyTealBright,
          size: 34,
        ),
      ),
    );
  }
}
