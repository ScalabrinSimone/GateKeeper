import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../shared/widgets/gk_button.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/gk_text_field.dart';

//Schermata di login: identifier (username o email) + password.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
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

    return AuthScaffold(
      title: l10n.t('signInTitle'),
      subtitle: houseName != null
          ? '${l10n.t('signInWelcome')} $houseName'
          : l10n.t('signInSubtitle'),
      child: Form(
        key: _formKey,
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
            GKTextField(
              controller: _passwordCtrl,
              label: l10n.t('password'),
              prefixIcon: Icons.lock_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.isEmpty) ? l10n.t('requiredField') : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                  label: Text(_obscure ? l10n.t('show') : l10n.t('hide')),
                ),
                TextButton(
                  onPressed: () => context.go('/recover'),
                  child: Text(l10n.t('forgotPassword')),
                ),
              ],
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
            const SizedBox(height: 12),
            GKButton(
              onPressed: _busy ? null : _submit,
              label: _busy ? l10n.t('loadingDots') : l10n.t('signInAction'),
              icon: Icons.login_rounded,
              expanded: true,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.go('/welcome'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.t('back')),
            ),
          ],
        ),
      ),
    );
  }
}
