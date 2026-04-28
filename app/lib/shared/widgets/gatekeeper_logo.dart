import 'package:flutter/material.dart';

/// Logo GateKeeper mostrato in cima alla sidebar.
///
/// Usa l'immagine `assets/images/logo.png` esportata da Figma.
/// Se l'immagine non è ancora presente (durante lo sviluppo),
/// ricade sul logo SVG/testo di fallback.
///
/// TODO: sostituire `_useFallback` con false quando aggiungi logo.png agli asset.
class GateKeeperLogo extends StatelessWidget {
  const GateKeeperLogo({super.key});

  // Imposta a false quando hai esportato il logo da Figma in assets/images/logo.png
  static const bool _useFallback = true;

  @override
  Widget build(BuildContext context) {
    if (!_useFallback) {
      return Image.asset(
        'assets/images/logo.png',
        height: 48,
        fit: BoxFit.contain,
      );
    }

    // Fallback: logo testuale fedele alla palette GateKeeper
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF00767A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.door_front_door_outlined,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Gate',
                style: TextStyle(
                  color: Color(0xFFFFA400),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Keeper',
                style: TextStyle(
                  color: Color(0xFFF4F7FB),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
