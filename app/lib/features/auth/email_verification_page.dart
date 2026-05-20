import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/gatekeeper_api.dart';
import 'widgets/auth_quick_actions.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/gk_text_field.dart';

/// Schermata mostrata dopo il login quando l'email non è ancora verificata.
/// L'utente deve inserire il codice a 6 cifre ricevuto via email.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.auth,
    required this.settings,
  });

  final AuthController auth;
  final SettingsController settings;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  static const _cooldownSeconds = 60;

  final _codeCtrl = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _error;

  // Timer cooldown reinvio.
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Invia automaticamente il codice al primo accesso.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    if (_cooldown > 0) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await GateKeeperApi.instance.auth.sendEmailCode();
      if (mounted) {
        setState(() => _codeSent = true);
        _startCooldown();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await GateKeeperApi.instance.auth.verifyEmail(code);
      // Ricarica l'utente: refreshUser() avanza lo stage ad authenticated.
      await widget.auth.refreshUser();
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).t('verifyEmailError'));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _logout() async {
    await widget.auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final email = widget.auth.user?.email ?? '';
    final canResend = _codeSent && !_sending && _cooldown <= 0;

    return AuthScaffold(
      title: l10n.t('verifyEmail'),
      subtitle: l10n.t('verifyEmailSubtitle'),
      trailing: AuthQuickActions(settings: widget.settings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icona decorativa
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.orangeGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: AppColors.orangeGold,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (email.isNotEmpty)
            Center(
              child: Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.stormyTeal,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (_sending)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: AppColors.stormyTeal),
              ),
            )
          else if (_codeSent) ...[
            GKTextField(
              controller: _codeCtrl,
              label: l10n.t('verifyEmailCodeHint'),
              prefixIcon: Icons.pin_rounded,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _verifying ? null : _verify,
              icon: _verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(l10n.t('verifyEmailConfirm')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.stormyTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // Reinvia codice con cooldown.
          if (_codeSent)
            TextButton.icon(
              onPressed: canResend ? _sendCode : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                _cooldown > 0
                    ? '${l10n.t('verifyEmailSend')} ($_cooldown s)'
                    : l10n.t('verifyEmailSend'),
              ),
            ),
          const SizedBox(height: 8),
          // Logout
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(l10n.t('logout')),
          ),
        ],
      ),
    );
  }
}
