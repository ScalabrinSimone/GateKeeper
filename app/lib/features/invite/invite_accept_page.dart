import 'package:flutter/material.dart';
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
class InviteAcceptPage extends StatefulWidget {
  const InviteAcceptPage({super.key, required this.auth, required this.settings, this.token});

  final AuthController auth;
  final SettingsController settings;
  final String? token;

  @override
  State<InviteAcceptPage> createState() => _InviteAcceptPageState();
}

class _InviteAcceptPageState extends State<InviteAcceptPage> {
  final _tokenCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  InviteDto? _invite;

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
    super.dispose();
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
        if (inv.suggestedName != null) _usernameCtrl.text = inv.suggestedName!;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  //Apre lo scanner camera in modalità invito. Il token estratto viene
  //inserito nel campo e poi verificato automaticamente.
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await GateKeeperApi.instance.invites.accept(
        token: _invite!.token,
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      //Login automatico dopo accettazione.
      final token = res['token']?.toString();
      if (token != null && token.isNotEmpty) {
        GateKeeperApi.instance.setToken(token);
        await SecureStorage.write('gk.auth.token', token);
        await widget.auth.bootstrap();
      }
      if (mounted) context.go('/dashboard');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return AuthScaffold(
      title: l10n.t('inviteAcceptTitle'),
      subtitle: l10n.t('inviteAcceptSubtitle'),
      trailing: AuthQuickActions(settings: widget.settings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GKTextField(
            controller: _tokenCtrl,
            label: l10n.t('inviteCode'),
            prefixIcon: Icons.qr_code_rounded,
          ),
          //Pulsante per scansionare il QR dall'app di chi ha generato
          //l'invito. Solo dove c'è una camera supportata.
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
            label: _invite != null ? l10n.t('codeVerified') : l10n.t('verifyCode'),
            icon: _invite != null ? Icons.verified_rounded : Icons.check_rounded,
            variant: _invite != null ? GKButtonVariant.outline : GKButtonVariant.secondary,
            expanded: true,
          ),
          if (_invite != null) ...[
            const SizedBox(height: 14),
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
              label: '${l10n.t('email')} (${l10n.t('optional')})',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            GKTextField(
              controller: _passwordCtrl,
              label: l10n.t('password'),
              prefixIcon: Icons.lock_rounded,
              obscureText: true,
            ),
            GKButton(
              onPressed: _busy ? null : () => _accept(l10n),
              label: l10n.t('joinHome'),
              icon: Icons.check_rounded,
              expanded: true,
            ),
          ],
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
      ),
    );
  }
}
