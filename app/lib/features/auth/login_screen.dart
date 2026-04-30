import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../router/app_router.dart';
import '../../shared/widgets/gatekeeper_logo.dart';
import '../../shared/widgets/gk_text_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Schermata di login completa per GateKeeper.
///
/// Obiettivo di questa schermata:
/// - raccogliere URL del gateway (Cloudflare Tunnel locale)
/// - email e password dell'utente
/// - eseguire un login **locale/mocked** tramite [AuthService]
/// - aggiornare [AuthState] e redirigere alla dashboard
///
/// NON chiama ancora il backend reale: [AuthService.login] simula
/// la latenza e restituisce un utente finto. Quando il Raspberry e
/// FastAPI saranno pronti, sarà sufficiente sostituire il corpo di
/// `AuthService.login` mantenendo intatta questa UI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller per i tre campi principali.
  final _gatewayCtrl = TextEditingController(text: 'https://gateway.local');
  final _emailCtrl = TextEditingController(text: 'simone@gatekeeper.local');
  final _passwordCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _gatewayCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.login(
        baseUrl: _gatewayCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Segniamo l'utente come loggato per il redirect globale in AppRouter.
      AuthState.instance.setLoggedIn(true);

      if (!mounted) return;
      context.go('/dashboard');
    } on AuthException catch (e) {
      // AuthException è definita in auth_service.dart e viene lanciata
      // quando le credenziali sono errate o il gateway non risponde.
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkBlack,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: GateKeeperLogo(height: 72)),
                const SizedBox(height: 32),
                Text(
                  'Sign in to GateKeeper',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connect to your home gateway and manage users, objects and alerts.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GkTextField(
                        label: 'Gateway URL',
                        hint: 'https://xxxxx.trycloudflare.com',
                        controller: _gatewayCtrl,
                        keyboardType: TextInputType.url,
                        prefixIcon: Icons.cloud_outlined,
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'Gateway URL is required';
                          }
                          if (!v.startsWith('http')) {
                            return 'Must start with http or https';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GkTextField(
                        label: 'Email',
                        hint: 'user@gatekeeper.local',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GkTextField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 4) {
                            return 'Password too short';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.stormyTeal,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This is a local-only mock login. No real network calls are performed yet.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
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
