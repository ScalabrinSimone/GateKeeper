import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/dto.dart';
import '../../../shared/widgets/gk_branded_qr.dart';
import '../../../shared/widgets/gk_button.dart';

//Dialog di condivisione di un invito appena generato.
//Mostra il codice testuale, il QR-code e i pulsanti "Copia codice" /
//"Copia messaggio". Il QR contiene il token in un formato compatto:
//
//   gatekeeper-invite://<token>
//
//Lo scanner dell'app riconosce sia URL sia JSON, quindi un membro può:
//- copiare il messaggio testuale dal chat,
//- oppure inquadrare il QR direttamente dalla schermata dell'invitante.
class InviteShareDialog extends StatelessWidget {
  const InviteShareDialog({super.key, required this.invite});

  final InviteDto invite;

  String get _deepLink => 'gatekeeper-invite://${invite.token}';

  String _shareMessage(AppL10n l10n) =>
      'Ti invito su GateKeeper (ruolo: ${invite.role}).\n'
      'Apri l\'app, scegli "Ho un codice di invito" e incolla:\n'
      '${invite.token}\n'
      'Oppure inquadra il QR mostrato sull\'app.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

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
      content: Container(
        width: 350, // Larghezza fissa per risolvere il problema di layout
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
                  '${l10n.t('role')}: ${invite.role.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.stormyTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            //QR code "branded": colori GateKeeper + logo al centro.
            Center(child: GKBrandedQr(data: _deepLink, size: 220)),
            const SizedBox(height: 12),
            //Codice testuale (sempre disponibile come fallback).
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                invite.token,
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
            GKButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invite.token));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('inviteCopiedBody'))),
                );
              },
              icon: Icons.tag_rounded,
              label: l10n.t('copyCode'),
              variant: GKButtonVariant.ghost,
              dense: true,
            ),
            GKButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _shareMessage(l10n)));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.t('inviteMessageCopied'))),
                );
              },
              icon: Icons.share_rounded,
              label: l10n.t('copyMessage'),
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
