import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/dto.dart';
import '../../../shared/widgets/gk_branded_qr.dart';
import '../../../shared/widgets/gk_button.dart';

//Dialog di condivisione di un invito appena generato.
//Su mobile mostra il tasto "Condividi" che apre il share sheet nativo.
//Su desktop il tasto "Condividi" non compare (solo copia codice).
//Le operazioni di copia sono silenziose (nessuna snackbar).
class InviteShareDialog extends StatefulWidget {
  const InviteShareDialog({super.key, required this.invite});

  final InviteDto invite;

  @override
  State<InviteShareDialog> createState() => _InviteShareDialogState();
}

class _InviteShareDialogState extends State<InviteShareDialog> {
  //Stato per il feedback visivo icona copia → tick.
  bool _codeCopied = false;

  String get _deepLink => 'gatekeeper-invite://${widget.invite.token}';

  String _shareMessage(AppL10n l10n) =>
      'Ti invito su GateKeeper (ruolo: ${widget.invite.role}).\n'
      'Apri l\'app, scegli "Ho un codice di invito" e incolla:\n'
      '${widget.invite.token}\n'
      'Oppure inquadra il QR mostrato sull\'app.';

  Future<void> _copyCode(AppL10n l10n) async {
    await Clipboard.setData(ClipboardData(text: widget.invite.token));
    //Feedback visivo: icona → tick per 2s, silenzioso (nessuna snackbar).
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  Future<void> _share(AppL10n l10n) async {
    //Share sheet nativo (Android/iOS).
    try {
      await Share.share(
        _shareMessage(l10n),
        subject: 'Invito GateKeeper',
      );
    } catch (_) {
      //Fallback silenzioso: copia negli appunti.
      await Clipboard.setData(ClipboardData(text: _shareMessage(l10n)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);
    final isMobile = PlatformInfo.isMobile;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded, color: AppColors.stormyTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.t('inviteByCode')),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //Badge ruolo.
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.stormyTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${l10n.t('role')}: ${widget.invite.role.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.stormyTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            //QR code branded.
            Center(child: GKBrandedQr(data: _deepLink, size: 220)),
            const SizedBox(height: 12),
            //Codice testuale.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                widget.invite.token,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            //Pulsante copia codice con feedback icona → tick.
            GKButton(
              onPressed: () => _copyCode(l10n),
              icon: _codeCopied ? Icons.check_circle_rounded : Icons.tag_rounded,
              label: l10n.t('copyCode'),
              variant: GKButtonVariant.ghost,
              dense: true,
            ),
            //Pulsante condividi: solo su mobile.
            if (isMobile)
              GKButton(
                onPressed: () => _share(l10n),
                icon: Icons.share_rounded,
                label: l10n.t('share'),
                variant: GKButtonVariant.secondary,
                dense: true,
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('close')),
            ),
          ],
        ),
      ],
    );
  }
}
