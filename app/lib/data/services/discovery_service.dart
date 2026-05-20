import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/platform/platform_info.dart';

//Risultato di una scoperta in LAN: un Raspberry/hub che ha risposto.
class DiscoveredHub {
  const DiscoveredHub({
    required this.host,
    required this.apiPort,
    required this.paired,
    this.houseName,
    this.version,
  });

  final String host;
  final int apiPort;
  final bool paired;
  final String? houseName;
  final int? version;

  String get baseUrl => 'http://$host:$apiPort';

  @override
  bool operator ==(Object other) =>
      other is DiscoveredHub && other.host == host && other.apiPort == apiPort;

  @override
  int get hashCode => Object.hash(host, apiPort);
}

//Servizio di discovery LAN: invia un broadcast UDP e raccoglie le risposte.
//Sul web il discovery non è possibile (no UDP nei browser): si restituisce
//una lista vuota.
class DiscoveryService {
  DiscoveryService._();

  static const int _discoveryPort = 51820;
  static const String _magic = 'GATEKEEPER_DISCOVER?';

  //Lancia il discovery e ritorna la lista di hub trovati entro `duration`.
  //La progress callback (`onFound`) viene invocata mano a mano che arrivano risposte.
  static Future<List<DiscoveredHub>> discover({
    Duration duration = const Duration(seconds: 3),
    void Function(DiscoveredHub hub)? onFound,
  }) async {
    if (!PlatformInfo.canPairDevice) return <DiscoveredHub>[];

    final results = <DiscoveredHub>{};
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      //Manda il broadcast su 255.255.255.255 e su alcune subnet comuni.
      final payload = utf8.encode(_magic);
      final targets = <InternetAddress>[
        InternetAddress('255.255.255.255'),
      ];
      for (final t in targets) {
        try {
          socket.send(payload, t, _discoveryPort);
        } catch (_) {}
      }

      final completer = Completer<void>();
      Timer? timeoutTimer;

      final sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket!.receive();
        if (dg == null) return;
        try {
          final text = utf8.decode(dg.data);
          final map = jsonDecode(text);
          if (map is! Map) return;
          if (map['kind'] != 'GATEKEEPER_HUB') return;
          final hub = DiscoveredHub(
            host: dg.address.address,
            apiPort: (map['api_port'] as num?)?.toInt() ?? 8000,
            paired: map['paired'] == true,
            houseName: map['house_name']?.toString(),
            version: (map['version'] as num?)?.toInt(),
          );
          if (results.add(hub) && onFound != null) onFound(hub);
        } catch (_) {
          //Ignora pacchetti malformati.
        }
      });

      timeoutTimer = Timer(duration, () {
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;
      await sub.cancel();
      timeoutTimer.cancel();
    } catch (_) {
      //Errore di socket: probabilmente piattaforma non supportata.
    } finally {
      socket?.close();
    }

    return results.toList();
  }
}
