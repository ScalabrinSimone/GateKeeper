import 'package:flutter/foundation.dart';

//Helper per riconoscere la piattaforma e abilitare feature condizionali.
class PlatformInfo {
  PlatformInfo._();

  //Web ha API limitate: niente discovery UDP, niente notifiche persistenti.
  static bool get isWeb => kIsWeb;

  //Mobile = Android/iOS.
  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  //Desktop = Windows/macOS/Linux.
  static bool get isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  //Il pairing del Raspberry è permesso solo da PC o smartphone.
  //Sul web mostriamo solo la schermata di login.
  static bool get canPairDevice => !kIsWeb;

  //Le notifiche persistenti (con app spenta) sono pratiche solo su mobile.
  //Su desktop le useremo come notifiche di sistema mentre l'app è aperta.
  static bool get supportsPushWhenClosed => isMobile;
}
