import 'package:flutter/material.dart';

/// Logo GateKeeper usato nel login e nella sidebar.
///
/// In un unico posto così, se in futuro passiamo dal PNG all'SVG
/// (usando flutter_svg) sarà sufficiente modificare questo widget.
///
/// TODO: sostituire Image.asset con SvgPicture.asset quando il logo
/// SVG ufficiale sarà disponibile:
///
/// ```dart
/// // Dipendenza già presente in pubspec.yaml:
/// // flutter_svg: ^2.0.10
/// import 'package:flutter_svg/flutter_svg.dart';
///
/// SvgPicture.asset('assets/images/gatekeeper_logo.svg', ...)
/// ```
class GateKeeperLogo extends StatelessWidget {
  const GateKeeperLogo({super.key, this.height = 64, this.compact = false});

  /// Altezza desiderata del logo.
  final double height;

  /// Se `true` usa una versione più compatta (es. sidebar stretta).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/gatekeeper_logo.png',
      height: height,
      // La versione compatta può essere gestita con padding/clip nel parent.
    );
  }
}
