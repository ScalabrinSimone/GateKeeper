import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

//Logo dell'app GateKeeper.
//Prova prima a caricare l'immagine reale `assets/icons/logo.png` (il marchio
//ufficiale: porta teal + scritta arancio + onde Wi-Fi). Se l'asset manca
//(es. setup iniziale) fa fallback al monogramma "GK" stilizzato.
//Il fallback evita errori di build se il file PNG non è ancora in posizione.
class GKLogo extends StatelessWidget {
  const GKLogo({super.key, this.size = 36, this.tight = false});

  final double size;
  //Se true rimuove padding/sfondo: utile quando il logo è già dentro a una
  //card che fornisce il proprio sfondo.
  final bool tight;

  static const String _assetPath = 'assets/icons/logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _Fallback(size: size),
    );
  }
}

//Fallback testuale "GK" usato quando l'asset PNG non è disponibile.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.orangeGold : AppColors.stormyTeal;
    final fg = isDark ? AppColors.inkBlack : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Text(
        'GK',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.36,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
