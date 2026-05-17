import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/dto.dart';
import '../../data/gatekeeper_api.dart';
import '../../shared/widgets/gk_button.dart';
import '../auth/widgets/auth_quick_actions.dart';
import '../auth/widgets/auth_scaffold.dart';
import '../auth/widgets/gk_text_field.dart';
import '../members/widgets/invite_share_dialog.dart';

//Wizard di prima configurazione, stile "prodotto consumer".
//Step 0 - Welcome: piccola intro pop su come funziona il sistema.
//Step 1 - Admin: nome casa, username, email, password, factory_code (se richiesto).
//Step 2 - Tag essenziali: l'utente sceglie qualche oggetto/tag iniziale.
//Step 3 - Invita membri: link condivisibili per ogni ruolo.
//Step 4 - Fatto: porta in app.
class SetupWizardPage extends StatefulWidget {
  const SetupWizardPage({
    super.key,
    required this.auth,
    required this.settings,
    this.prefilledFactoryCode,
  });
  final AuthController auth;
  final SettingsController settings;
  //Se ricevuto via QR / route, il wizard pre-compila il factory_code.
  final String? prefilledFactoryCode;

  @override
  State<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends State<SetupWizardPage> {
  int _step = 0;

  //Step 1 controllers.
  final _houseCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final TextEditingController _factoryCtrl = TextEditingController(
    text: widget.prefilledFactoryCode ?? '',
  );
  bool _busy = false;
  String? _error;

  //Step 2: tag essenziali da creare. Coppie (nome, categoria).
  final List<_TagSelection> _selectedTags = [];
  bool _creatingTags = false;

  //Step 3: inviti generati.
  final List<InviteDto> _invites = [];
  bool _creatingInvite = false;

  @override
  void dispose() {
    _houseCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _factoryCtrl.dispose();
    super.dispose();
  }

  bool get _needsFactoryCode => widget.auth.hubInfo?.requiresFactoryCode ?? false;

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  Future<void> _submitAdmin(AppL10n l10n) async {
    if (_busy) return;
    if (_houseCtrl.text.trim().isEmpty ||
        _usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.length < 6) {
      setState(() => _error = l10n.t('fillAllFields'));
      return;
    }
    if (!_emailRegex.hasMatch(_emailCtrl.text.trim())) {
      setState(() => _error = l10n.t('invalidEmail'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await widget.auth.pairAndLogin(
        houseName: _houseCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        email: _emailCtrl.text.trim(),
        factoryCode: _factoryCtrl.text.trim().isEmpty ? null : _factoryCtrl.text.trim(),
      );
      // Se l'email non è verificata il router reindirizzerà a /verify-email;
      // altrimenti avanziamo normalmente agli step successivi del wizard.
      if (widget.auth.stage == AuthStage.needsEmailVerification) return;
      setState(() => _step = 2);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createSelectedTags() async {
    if (_selectedTags.isEmpty) {
      setState(() => _step = 3);
      return;
    }
    setState(() => _creatingTags = true);
    try {
      for (final sel in _selectedTags) {
        await GateKeeperApi.instance.devices.create(
          name: sel.name,
          category: sel.category,
          isEssential: sel.essential,
        );
      }
      if (mounted) setState(() => _step = 3);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _creatingTags = false);
    }
  }

  Future<void> _generateInvite(String role) async {
    setState(() => _creatingInvite = true);
    try {
      final invite = await GateKeeperApi.instance.invites.create(role: role);
      if (mounted) setState(() => _invites.add(invite));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _creatingInvite = false);
    }
  }

  void _finish(BuildContext context) {
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final steps = <Widget>[
      _WelcomeStep(onNext: () => setState(() => _step = 1)),
      _AdminStep(
        houseCtrl: _houseCtrl,
        usernameCtrl: _usernameCtrl,
        emailCtrl: _emailCtrl,
        passwordCtrl: _passwordCtrl,
        factoryCtrl: _factoryCtrl,
        needsFactoryCode: _needsFactoryCode,
        busy: _busy,
        error: _error,
        onSubmit: () => _submitAdmin(l10n),
        onBack: () => setState(() => _step = 0),
      ),
      _TagsStep(
        selected: _selectedTags,
        busy: _creatingTags,
        onSubmit: _createSelectedTags,
      ),
      _InviteStep(
        invites: _invites,
        busy: _creatingInvite,
        onGenerate: _generateInvite,
        onContinue: () => setState(() => _step = 4),
      ),
      _DoneStep(onFinish: () => _finish(context)),
    ];

    return AuthScaffold(
      title: l10n.t('setupTitle'),
      subtitle: '${l10n.t('step')} ${_step + 1} / ${steps.length}',
      trailing: AuthQuickActions(settings: widget.settings),
      //Tasto "Indietro" in alto a sinistra: utile se l'utente vuole
      //tornare alla schermata di scelta hub o annullare la configurazione.
      leading: IconButton(
        tooltip: l10n.t('back'),
        onPressed: () => _exitSetup(context, l10n),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_step), child: steps[_step]),
      ),
      actionsBelow: _StepIndicator(current: _step, total: steps.length),
    );
  }

  //Chiude il wizard riportando l'utente alla scelta hub/login.
  //Se siamo oltre lo step di creazione admin, chiediamo conferma:
  //l'admin è stato già creato e una nuova "fuga" non lo elimina.
  Future<void> _exitSetup(BuildContext context, AppL10n l10n) async {
    // Step 1: torna allo step 0 senza uscire dal wizard.
    if (_step == 1) {
      setState(() => _step = 0);
      return;
    }
    if (_step >= 2) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.t('exitSetupTitle')),
          content: Text(l10n.t('exitSetupBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.t('exitAction')),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!context.mounted) return;
      //Andiamo direttamente in dashboard: l'admin è stato creato e siamo
      //già autenticati.
      context.go('/dashboard');
      return;
    }
    if (!context.mounted) return;
    context.go('/welcome');
  }
}

//Modello di selezione tag.
class _TagSelection {
  _TagSelection(this.name, this.category, this.essential, this.icon);
  final String name;
  final String category;
  bool essential;
  final IconData icon;
  bool selected = false;
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == current ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.stormyTeal : AppColors.charcoalBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 0 — WELCOME
// ---------------------------------------------------------------------------
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final tips = <(IconData, String, String)>[
      (Icons.shield_rounded, l10n.t('setupTip1Title'), l10n.t('setupTip1Body')),
      (Icons.sensors_rounded, l10n.t('setupTip2Title'), l10n.t('setupTip2Body')),
      (Icons.notifications_active_rounded, l10n.t('setupTip3Title'), l10n.t('setupTip3Body')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('welcomeHubReady'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.stormyTeal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.stormyTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tip.$1, color: AppColors.stormyTeal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip.$2,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(tip.$3,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        GKButton(
          onPressed: onNext,
          label: l10n.t('startSetup'),
          icon: Icons.arrow_forward_rounded,
          expanded: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 1 — ADMIN
// ---------------------------------------------------------------------------
class _AdminStep extends StatelessWidget {
  const _AdminStep({
    required this.houseCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.factoryCtrl,
    required this.needsFactoryCode,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController houseCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController factoryCtrl;
  final bool needsFactoryCode;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GKTextField(
          controller: houseCtrl,
          label: l10n.t('houseName'),
          prefixIcon: Icons.home_rounded,
        ),
        GKTextField(
          controller: usernameCtrl,
          label: l10n.t('adminUsername'),
          prefixIcon: Icons.person_rounded,
        ),
        GKTextField(
          controller: emailCtrl,
          label: l10n.t('email'),
          prefixIcon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        GKTextField(
          controller: passwordCtrl,
          label: l10n.t('password'),
          prefixIcon: Icons.lock_rounded,
          obscureText: true,
        ),
        if (needsFactoryCode)
          GKTextField(
            controller: factoryCtrl,
            label: l10n.t('factoryCode'),
            prefixIcon: Icons.qr_code_2_rounded,
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(error!, style: const TextStyle(color: AppColors.danger)),
          ),
        const SizedBox(height: 6),
        GKButton(
          onPressed: busy ? null : onSubmit,
          label: busy ? l10n.t('loadingDots') : l10n.t('createAndPair'),
          icon: Icons.check_rounded,
          expanded: true,
        ),
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(l10n.t('back')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 2 — TAGS
// ---------------------------------------------------------------------------
class _TagsStep extends StatefulWidget {
  const _TagsStep({
    required this.selected,
    required this.busy,
    required this.onSubmit,
  });

  final List<_TagSelection> selected;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  State<_TagsStep> createState() => _TagsStepState();
}

class _TagsStepState extends State<_TagsStep> {
  late final List<_TagSelection> _options;

  @override
  void initState() {
    super.initState();
    _options = [
      _TagSelection('Chiavi di casa', 'keys', true, Icons.vpn_key_rounded),
      _TagSelection('Portafoglio', 'wallet', true, Icons.account_balance_wallet_rounded),
      _TagSelection('Ombrello', 'umbrella', false, Icons.umbrella_rounded),
      _TagSelection('Zaino scuola', 'bag', true, Icons.work_rounded),
      _TagSelection('Telefono', 'phone', true, Icons.smartphone_rounded),
    ];
  }

  void _toggle(_TagSelection sel) {
    setState(() {
      sel.selected = !sel.selected;
      if (sel.selected) {
        if (!widget.selected.contains(sel)) widget.selected.add(sel);
      } else {
        widget.selected.remove(sel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('tagsStepHint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in _options)
              _TagChip(selection: t, onTap: () => _toggle(t)),
          ],
        ),
        const SizedBox(height: 18),
        GKButton(
          onPressed: widget.busy ? null : widget.onSubmit,
          label: widget.busy
              ? l10n.t('loadingDots')
              : (widget.selected.isEmpty ? l10n.t('skipForNow') : l10n.t('createTagsAndContinue')),
          icon: Icons.arrow_forward_rounded,
          expanded: true,
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.selection, required this.onTap});
  final _TagSelection selection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selection.selected ? AppColors.stormyTeal : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (selection.selected ? AppColors.stormyTeal : AppColors.charcoalBlue).withValues(alpha: 0.08),
            border: Border.all(
              color: (selection.selected ? AppColors.stormyTeal : Colors.transparent).withValues(alpha: 0.45),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selection.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                selection.name,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 3 — INVITES
// ---------------------------------------------------------------------------
class _InviteStep extends StatelessWidget {
  const _InviteStep({
    required this.invites,
    required this.busy,
    required this.onGenerate,
    required this.onContinue,
  });

  final List<InviteDto> invites;
  final bool busy;
  final Future<void> Function(String role) onGenerate;
  final VoidCallback onContinue;

  String _shareText(InviteDto inv) {
    return 'Ti invito su GateKeeper!\n'
        'Apri l\'app, scegli "Ho un invito" e incolla questo codice:\n'
        '${inv.token}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('inviteStepHint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GKButton(
                onPressed: busy ? null : () => onGenerate('adult'),
                label: l10n.t('inviteAdult'),
                icon: Icons.person_rounded,
                variant: GKButtonVariant.outline,
                dense: true,
                expanded: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GKButton(
                onPressed: busy ? null : () => onGenerate('child'),
                label: l10n.t('inviteChild'),
                icon: Icons.child_care_rounded,
                variant: GKButtonVariant.outline,
                dense: true,
                expanded: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (invites.isEmpty)
          Text(
            l10n.t('noInvitesYet'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        for (final inv in invites)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stormyTeal.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.stormyTeal.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded, color: AppColors.stormyTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.role.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w900,
                          color: AppColors.stormyTeal,
                        ),
                      ),
                      SelectableText(
                        inv.token,
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('showInviteQr'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => InviteShareDialog(invite: inv),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.stormyTeal),
                ),
                IconButton(
                  tooltip: l10n.t('copyCode'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _shareText(inv)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.t('copiedToClipboard'))),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        GKButton(
          onPressed: onContinue,
          label: l10n.t('finishSetup'),
          icon: Icons.check_rounded,
          expanded: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 4 — DONE
// ---------------------------------------------------------------------------
class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.stormyTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.celebration_rounded, color: AppColors.stormyTeal, size: 48),
              const SizedBox(height: 8),
              Text(
                l10n.t('setupCompleteTitle'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('setupCompleteSubtitle'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GKButton(
          onPressed: onFinish,
          label: l10n.t('openApp'),
          icon: Icons.arrow_forward_rounded,
          expanded: true,
        ),
      ],
    );
  }
}
