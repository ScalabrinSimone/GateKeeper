import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

//QR code "branded" GateKeeper:
//- occhi in stormy teal (riconoscibili come elementi del brand);
//- moduli dati a pallini (puntinato morbido, look moderno);
//- logo dell'app al centro se l'asset `assets/icons/logo.png` esiste.
//Il QR sta sempre su sfondo bianco per garantire la leggibilità: scanner
//economici e fotocamere con poca luce non sempre leggono QR su sfondo scuro.
class GKBrandedQr extends StatefulWidget {
  const GKBrandedQr({
    super.key,
    required this.data,
    this.size = 220,
    this.padding = 12,
  });

  final String data;
  final double size;
  final double padding;

  @override
  State<GKBrandedQr> createState() => _GKBrandedQrState();
}

class _GKBrandedQrState extends State<GKBrandedQr> {
  //Verifichiamo una volta sola se l'asset logo esiste: l'embedded image
  //richiede un AssetImage valido, altrimenti il render esplode in runtime.
  bool? _hasLogo;

  @override
  void initState() {
    super.initState();
    _probeLogo();
  }

  Future<void> _probeLogo() async {
    try {
      await rootBundle.load('assets/icons/logo.png');
      if (mounted) setState(() => _hasLogo = true);
    } catch (_) {
      if (mounted) setState(() => _hasLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size * 0.22;

    return Container(
      padding: EdgeInsets.all(widget.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: QrImageView(
        data: widget.data,
        size: widget.size,
        backgroundColor: Colors.white,
        //Correzione errori alta: serve quando aggiungiamo un logo al centro
        //perché copre parte dei moduli del QR.
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.stormyTeal,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: AppColors.inkBlack,
        ),
        //Logo centrale: aggiunto solo se l'asset esiste davvero.
        embeddedImage: _hasLogo == true
            ? const AssetImage('assets/icons/logo.png')
            : null,
        embeddedImageStyle: _hasLogo == true
            ? QrEmbeddedImageStyle(size: Size(logoSize, logoSize))
            : null,
      ),
    );
  }
}
