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

  //La scansione QR via camera è supportata solo dove esiste l'implementazione
  //nativa del plugin `mobile_scanner`: Android, iOS, macOS e Web (limitato).
  //Su Windows/Linux il plugin lancia MissingPluginException, quindi nascondiamo
  //il bottone e mostriamo solo l'inserimento manuale del codice/URL.
  static bool get canScanQr {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  //Le notifiche persistenti (con app spenta) sono pratiche solo su mobile.
  //Su desktop le useremo come notifiche di sistema mentre l'app è aperta.
  static bool get supportsPushWhenClosed => isMobile;
}
