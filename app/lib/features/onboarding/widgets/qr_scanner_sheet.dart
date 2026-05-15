import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/dto.dart';

//Sheet che mostra la camera per scansionare un QR-code di pairing.
//Quando rileva un payload valido (`HubQrDto.looksValid`) lo restituisce
//via Navigator.pop. Funziona su Android/iOS; su Windows/Linux/macOS la
//camera viene tipicamente esposta dal sistema (best-effort).
class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      //Provo a interpretare il payload come JSON con kind=gatekeeper_pair.
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
                        l10n.t('scanPairingQr'),
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
                  l10n.t('scanPairingQrHint'),
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
                        child: Stack(
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
