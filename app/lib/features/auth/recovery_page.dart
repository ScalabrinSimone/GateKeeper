import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/gatekeeper_api.dart';
import '../../shared/widgets/gk_button.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/gk_text_field.dart';

//Recupero password in due step:
//1. l'utente inserisce la mail e riceve un codice (via SMTP o outbox.log),
//2. inserisce codice + nuova password.
class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key, required this.auth});
  final AuthController auth;

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  bool _busy = false;
  bool _emailSent = false;
  String? _info;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode(AppL10n l10n) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await GateKeeperApi.instance.auth.forgotPassword(_emailCtrl.text.trim());
      setState(() {
        _emailSent = true;
        _info = l10n.t('recoveryEmailSent');
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPwd(AppL10n l10n) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await GateKeeperApi.instance.auth.resetPassword(
        token: _tokenCtrl.text.trim(),
        newPassword: _newPwdCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _info = l10n.t('passwordResetOk');
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        context.go('/login');
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AuthScaffold(
      title: l10n.t('recoverTitle'),
      subtitle: l10n.t('recoverSubtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GKTextField(
            controller: _emailCtrl,
            label: l10n.t('email'),
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          GKButton(
            onPressed: _busy ? null : () => _sendCode(l10n),
            label: _emailSent ? l10n.t('resendCode') : l10n.t('sendCode'),
            icon: Icons.send_rounded,
            variant: GKButtonVariant.secondary,
            expanded: true,
          ),
          const SizedBox(height: 18),
          if (_emailSent) ...[
            GKTextField(
              controller: _tokenCtrl,
              label: l10n.t('resetCode'),
              prefixIcon: Icons.confirmation_number_rounded,
            ),
            GKTextField(
              controller: _newPwdCtrl,
              label: l10n.t('newPassword'),
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: true,
            ),
            GKButton(
              onPressed: _busy ? null : () => _resetPwd(l10n),
              label: l10n.t('setNewPassword'),
              icon: Icons.check_rounded,
              expanded: true,
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 12),
            _Banner(text: _info!, color: AppColors.stormyTeal),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _Banner(text: _error!, color: AppColors.danger),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(l10n.t('back')),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
