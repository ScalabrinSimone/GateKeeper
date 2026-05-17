import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../shared/widgets/gk_button.dart';
import 'widgets/auth_quick_actions.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/gk_text_field.dart';

//Schermata di login: identifier (username o email) + password.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth, required this.settings});

  final AuthController auth;
  final SettingsController settings;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }


  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await widget.auth.login(
        identifier: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      context.go('/dashboard');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final houseName = widget.auth.hubInfo?.houseName;
    //Se la casa ha un nome lo mostriamo come titolo principale: l'utente
    //vede subito a quale casa si sta connettendo. Il sottotitolo invita
    //ad accedere. Se manca il nome ricadiamo sul vecchio "Accedi".
    final hasHouseName = houseName != null && houseName.trim().isNotEmpty;

    return AuthScaffold(
      title: hasHouseName ? houseName : l10n.t('signInTitle'),
      subtitle: hasHouseName ? l10n.t('signInSubtitle') : l10n.t('signInDescription'),
      trailing: AuthQuickActions(settings: widget.settings),
      child: Form(
        key: _formKey,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GKTextField(
                  controller: _identifierCtrl,
                  label: l10n.t('usernameOrEmail'),
                  prefixIcon: Icons.person_rounded,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.t('requiredField') : null,
                ),
                const SizedBox(height: 16),
                GKTextField(
                  controller: _passwordCtrl,
                  label: l10n.t('password'),
                  prefixIcon: Icons.lock_rounded,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.t('requiredField') : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/recover'),
                    child: Text(l10n.t('forgotPassword')),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GKButton(
                  onPressed: _busy ? null : _submit,
                  label: _busy ? l10n.t('loadingDots') : l10n.t('signInAction'),
                  icon: Icons.login_rounded,
                  expanded: true,
                ),
                const SizedBox(height: 12),
                //Scorciatoia per chi è stato invitato: porta direttamente
                //alla pagina di accettazione invito (token o QR scan).
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => context.go('/invite'),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: Text(l10n.t('haveInvite')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.stormyTeal,
                    side: BorderSide(color: AppColors.stormyTeal.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/welcome'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l10n.t('back')),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              await widget.auth.leaveHome();
                              if (!context.mounted) return;
                              context.go('/welcome');
                            },
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: Text(l10n.t('leaveHome')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
