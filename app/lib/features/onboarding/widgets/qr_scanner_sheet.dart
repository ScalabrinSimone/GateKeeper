import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/dto.dart';

//Modalità della sheet: pairing dell'hub oppure accettazione invito.
//In `invite` accettiamo solo payload `gatekeeper-invite://<token>`
//oppure token grezzi (>= 8 caratteri); ritorniamo il token come String.
enum QrScannerMode { pair, invite }

//Sheet che mostra la camera per scansionare un QR-code.
//Modalità default: `pair` (legge `HubQrDto`). In modalità `invite` ritorna
//il token dell'invito come String. Funziona su Android/iOS/macOS/Web;
//su Windows/Linux ritorna un pannello di errore con suggerimento di
//inserire manualmente il codice.
class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({
    super.key,
    this.mode = QrScannerMode.pair,
  });

  final QrScannerMode mode;

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  //Sui device che non supportano mobile_scanner evitiamo proprio di creare
  //il controller (eviterebbe la MissingPluginException all'avvio).
  late final MobileScannerController? _controller = PlatformInfo.canScanQr
      ? MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          formats: const [BarcodeFormat.qrCode],
        )
      : null;
  bool _handled = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  //Estrae un token "pulito" dal payload QR di un invito.
  //Accetta `gatekeeper-invite://<token>` o token grezzo.
  String? _extractInviteToken(String raw) {
    final trimmed = raw.trim();
    const scheme = 'gatekeeper-invite://';
    if (trimmed.toLowerCase().startsWith(scheme)) {
      final tok = trimmed.substring(scheme.length).trim();
      return tok.isEmpty ? null : tok;
    }
    //Token grezzo: accettiamo solo se sembra ragionevole.
    if (trimmed.length >= 8 && !trimmed.contains(' ')) return trimmed;
    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      if (widget.mode == QrScannerMode.invite) {
        final tok = _extractInviteToken(raw);
        if (tok != null) {
          _handled = true;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(tok);
          return;
        }
        continue;
      }
      //Modalità pair: provo JSON poi URL.
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final dto = HubQrDto.fromJson(Map<String, dynamic>.from(decoded));
          if (dto.looksValid) {
            _handled = true;
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(dto);
            return;
          }
        }
      } catch (_) {
        //Non era JSON. Se è un URL semplice, lo passo come baseUrl.
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          _handled = true;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(HubQrDto(
            v: 1,
            kind: 'gatekeeper_pair',
            paired: false,
            baseUrl: raw.trim(),
          ));
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);
    final isInvite = widget.mode == QrScannerMode.invite;
    final title = isInvite ? l10n.t('scanInviteQr') : l10n.t('scanPairingQr');
    final hint = isInvite ? l10n.t('scanInviteQrHint') : l10n.t('scanPairingQrHint');

    return SafeArea(
      //Limite massimo per evitare overflow su finestre grandi (desktop/web).
      //Centriamo il contenuto e lasciamo il preview in proporzione 1:1
      //ma con un cap di 320px così resta sempre dentro la viewport.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.stormyTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                      maxHeight: 320,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _controller == null
                            //Su Windows/Linux il plugin non è disponibile:
                            //mostriamo un placeholder con suggerimento.
                            ? const _ScannerUnavailable()
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  MobileScanner(
                                    controller: _controller,
                                    onDetect: _onDetect,
                                    errorBuilder: (ctx, err, _) =>
                                        _ScannerError(error: err),
                                  ),
                                  //Overlay decorativo: cornice angolare.
                                  IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CornerFramePainter(),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Placeholder mostrato quando il plugin scanner non è disponibile sulla
//piattaforma corrente (tipicamente Windows o Linux desktop).
class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.desktop_access_disabled_rounded,
              color: AppColors.orangeGold, size: 38),
          const SizedBox(height: 12),
          Text(
            l10n.t('scannerUnavailable'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('scannerUnavailableHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_rounded,
              color: AppColors.danger, size: 36),
          const SizedBox(height: 10),
          Text(
            l10n.t('scannerError'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            error.errorDetails?.message ?? error.errorCode.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.stormyTeal
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 24.0;
    const inset = 18.0;
    final r = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, p);
      canvas.drawLine(b, c, p);
    }

    corner(Offset(r.left, r.top + len), Offset(r.left, r.top),
        Offset(r.left + len, r.top));
    corner(Offset(r.right - len, r.top), Offset(r.right, r.top),
        Offset(r.right, r.top + len));
    corner(Offset(r.right, r.bottom - len), Offset(r.right, r.bottom),
        Offset(r.right - len, r.bottom));
    corner(Offset(r.left + len, r.bottom), Offset(r.left, r.bottom),
        Offset(r.left, r.bottom - len));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
