import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/platform/platform_info.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/dto.dart';
import '../../data/gatekeeper_api.dart';
import '../../shared/widgets/gk_button.dart';
import '../auth/widgets/auth_quick_actions.dart';
import '../auth/widgets/auth_scaffold.dart';
import '../auth/widgets/gk_text_field.dart';
import '../onboarding/widgets/qr_scanner_sheet.dart';

//Pagina di accettazione invito.
//Può ricevere il token via path param (/invite/:token) oppure essere usata vuota
//e incollare il token a mano.
//
//Flusso:
//1. Inserisci/scansiona il codice invito.
//2. Compila username, email (OBBLIGATORIA), password.
//3. Dopo l'accettazione, viene inviato un codice di verifica a 6 cifre via email.
//4. L'utente inserisce il codice per completare la registrazione.
class InviteAcceptPage extends StatefulWidget {
  const InviteAcceptPage({super.key, required this.auth, required this.settings, this.token});

  final AuthController auth;
  final SettingsController settings;
  final String? token;

  @override
  State<InviteAcceptPage> createState() => _InviteAcceptPageState();
}

//Step del flusso di accettazione invito.
enum _InviteStep { tokenInput, formInput, emailVerification }

class _InviteAcceptPageState extends State<InviteAcceptPage> {
  final _tokenCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  InviteDto? _invite;

  //Step corrente del flusso.
  _InviteStep _step = _InviteStep.tokenInput;

  //Cooldown per reinvio codice email.
  static const _cooldownSeconds = 60;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  //Regex email: accetta domini multi-livello (es. 10933919@itisrossi.vi.it).
  static final _emailRegex = RegExp(r'^[\w.+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenCtrl.text = widget.token!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyToken());
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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

  Future<void> _verifyToken() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inv = await GateKeeperApi.instance.invites.getByToken(token);
      setState(() {
        _invite = inv;
        _step = _InviteStep.formInput;
        if (inv.suggestedName != null) _usernameCtrl.text = inv.suggestedName!;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  //Apre lo scanner camera in modalità invito.
  Future<void> _scanInviteQr() async {
    if (!PlatformInfo.canScanQr) {
      setState(() => _error = AppL10n.of(context).t('scannerUnavailableHint'));
      return;
    }
    final tok = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QrScannerSheet(mode: QrScannerMode.invite),
    );
    if (tok == null || !mounted) return;
    _tokenCtrl.text = tok;
    await _verifyToken();
  }

  Future<void> _accept(AppL10n l10n) async {
    if (_invite == null) {
      setState(() => _error = l10n.t('verifyInviteFirst'));
      return;
    }
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.length < 6) {
      setState(() => _error = l10n.t('fillAllFields'));
      return;
    }
    //Email obbligatoria con validazione.
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.t('emailRequired'));
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = l10n.t('invalidEmail'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final res = await GateKeeperApi.instance.invites.accept(
        token: _invite!.token,
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        email: email,
      );
      //Login automatico dopo accettazione.
      final token = res['token']?.toString();
      if (token != null && token.isNotEmpty) {
        GateKeeperApi.instance.setToken(token);
        await SecureStorage.write('gk.auth.token', token);
      }
      //Invia il codice di verifica email.
      try {
        await GateKeeperApi.instance.auth.sendEmailCode();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _step = _InviteStep.emailVerification;
          _error = null;
        });
        _startCooldown();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendCode() async {
    if (_cooldown > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GateKeeperApi.instance.auth.sendEmailCode();
      if (mounted) _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GateKeeperApi.instance.auth.verifyEmail(code);
      //Ricarica l'utente e vai alla dashboard.
      await widget.auth.bootstrap();
      if (mounted) context.go('/dashboard');
    } on ApiException catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).t('verifyEmailError'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppL10n.of(context).t('verifyEmailError'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  //Torna indietro di uno step.
  void _goBack() {
    setState(() {
      _error = null;
      switch (_step) {
        case _InviteStep.tokenInput:
          //Già al primo step: torna alla pagina welcome.
          context.go('/welcome');
          return;
        case _InviteStep.formInput:
          _step = _InviteStep.tokenInput;
          _invite = null;
        case _InviteStep.emailVerification:
          //Torna al form per correggere i dati.
          //Nota: l'account è già stato creato, ma l'utente può reinserire
          //il codice o tornare per vedere i dati inseriti.
          _step = _InviteStep.formInput;
          _codeCtrl.clear();
          _cooldownTimer?.cancel();
          _cooldown = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AuthScaffold(
      title: l10n.t('inviteAcceptTitle'),
      subtitle: _step == _InviteStep.emailVerification
          ? l10n.t('verifyEmailSubtitle')
          : l10n.t('inviteAcceptSubtitle'),
      trailing: AuthQuickActions(settings: widget.settings),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _buildStep(l10n),
        ),
      ),
    );
  }

  Widget _buildStep(AppL10n l10n) {
    switch (_step) {
      case _InviteStep.tokenInput:
        return _buildTokenStep(l10n);
      case _InviteStep.formInput:
        return _buildFormStep(l10n);
      case _InviteStep.emailVerification:
        return _buildVerificationStep(l10n);
    }
  }

  Widget _buildTokenStep(AppL10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GKTextField(
          controller: _tokenCtrl,
          label: l10n.t('inviteCode'),
          prefixIcon: Icons.qr_code_rounded,
        ),
        if (PlatformInfo.canScanQr) ...[
          GKButton(
            onPressed: _busy ? null : _scanInviteQr,
            label: l10n.t('scanInviteCta'),
            icon: Icons.qr_code_scanner_rounded,
            variant: GKButtonVariant.secondary,
            expanded: true,
          ),
          const SizedBox(height: 6),
        ],
        GKButton(
          onPressed: _busy ? null : _verifyToken,
          label: l10n.t('verifyCode'),
          icon: Icons.check_rounded,
          variant: GKButtonVariant.secondary,
          expanded: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(l10n.t('back')),
        ),
      ],
    );
  }

  Widget _buildFormStep(AppL10n l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.stormyTeal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.badge_rounded, color: AppColors.stormyTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                '${l10n.t('role')}: ${_invite!.role.toUpperCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.stormyTeal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GKTextField(
          controller: _usernameCtrl,
          label: l10n.t('username'),
          prefixIcon: Icons.person_rounded,
        ),
        GKTextField(
          controller: _emailCtrl,
          label: l10n.t('email'),
          prefixIcon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        GKTextField(
          controller: _passwordCtrl,
          label: l10n.t('password'),
          prefixIcon: Icons.lock_rounded,
          obscureText: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 6),
        GKButton(
          onPressed: _busy ? null : () => _accept(l10n),
          label: _busy ? l10n.t('loadingDots') : l10n.t('joinHome'),
          icon: Icons.check_rounded,
          expanded: true,
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(l10n.t('back')),
        ),
      ],
    );
  }

  Widget _buildVerificationStep(AppL10n l10n) {
    final email = _emailCtrl.text.trim();
    final canResend = !_busy && _cooldown <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //Icona decorativa.
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
        GKTextField(
          controller: _codeCtrl,
          label: l10n.t('verifyEmailCodeHint'),
          prefixIcon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: (_) => _verifyEmailCode(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _verifyEmailCode,
          icon: _busy
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
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        //Reinvia codice con cooldown.
        TextButton.icon(
          onPressed: canResend ? _resendCode : null,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            _cooldown > 0
                ? '${l10n.t('verifyEmailSend')} ($_cooldown s)'
                : l10n.t('verifyEmailSend'),
          ),
        ),
        const SizedBox(height: 8),
        //Torna indietro al form (per correggere email se sbagliata).
        TextButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(l10n.t('back')),
        ),
      ],
    );
  }
}
