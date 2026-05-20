import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/state/notifications_controller.dart';
import '../api/api_exception.dart';
import '../api/dto.dart';
import '../gatekeeper_api.dart';

//Servizio di polling eventi che controlla periodicamente il backend per
//nuovi eventi e mostra notifiche locali quando ne trova.
//
//Funzionamento:
//- Ogni N secondi chiama GET /events.
//- Confronta con l'ultimo evento noto (per id).
//- Se ci sono eventi nuovi, mostra una notifica locale per ciascuno.
//
//Questo approccio funziona su TUTTE le piattaforme (desktop, web, mobile)
//senza bisogno di Firebase/FCM. In futuro si può aggiungere WebSocket o
//Server-Sent Events per ridurre il polling.
class EventPollingService {
  EventPollingService._();
  static final EventPollingService instance = EventPollingService._();

  Timer? _timer;
  int? _lastKnownEventId;
  bool _running = false;

  //Intervallo di polling (secondi).
  static const _pollInterval = Duration(seconds: 5);

  //Avvia il polling. Chiamato dopo il login.
  void start() {
    if (_running) return;
    _running = true;
    //Prima esecuzione: carica l'ultimo id senza notificare (baseline).
    _initBaseline();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
    if (kDebugMode) {
      // ignore: avoid_print
      print('[EventPolling] Avviato (intervallo: ${_pollInterval.inSeconds}s)');
    }
  }

  //Ferma il polling. Chiamato al logout.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _lastKnownEventId = null;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[EventPolling] Fermato');
    }
  }

  //Carica l'ultimo evento come baseline (non notifica).
  Future<void> _initBaseline() async {
    try {
      final events = await GateKeeperApi.instance.events.list();
      if (events.isNotEmpty) {
        //Gli eventi sono ordinati per id crescente dal backend.
        _lastKnownEventId = events.map((e) => e.id).reduce((a, b) => a > b ? a : b);
      }
    } catch (_) {
      //Ignora errori di rete durante l'init.
    }
  }

  //Poll: controlla nuovi eventi e notifica.
  Future<void> _poll() async {
    if (!_running) return;
    try {
      final events = await GateKeeperApi.instance.events.list();
      if (events.isEmpty) return;

      final maxId = events.map((e) => e.id).reduce((a, b) => a > b ? a : b);

      //Se non abbiamo un baseline, impostiamolo ora senza notificare.
      if (_lastKnownEventId == null) {
        _lastKnownEventId = maxId;
        return;
      }

      //Filtra solo gli eventi nuovi (id > lastKnownEventId).
      final newEvents = events.where((e) => e.id > _lastKnownEventId!).toList();
      if (newEvents.isEmpty) return;

      //Aggiorna il baseline.
      _lastKnownEventId = maxId;

      //Mostra notifiche locali per gli eventi rilevanti.
      for (final event in newEvents) {
        await _notifyEvent(event);
      }
    } on ApiException catch (_) {
      //Ignora errori API (es. token scaduto, rete assente).
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[EventPolling] Errore poll: $e');
      }
    }
  }

  //Mostra una notifica locale per un evento.
  Future<void> _notifyEvent(EventDto event) async {
    final notifications = NotificationsController.instance;
    if (!notifications.supported) return;

    final (title, body, important) = _eventToNotification(event);
    if (title == null) return;

    await notifications.show(
      id: event.id,
      title: title,
      body: body ?? '',
      important: important,
    );
  }

  //"Traduce" un EventDto in titolo + corpo notifica.
  //Restituisce (null, null, false) se l'evento non merita una notifica.
  (String?, String?, bool) _eventToNotification(EventDto event) {
    switch (event.eventType) {
      case 'passage_out':
        return (
          '📦 Uscita rilevata',
          _describePassage(event, 'uscito'),
          false,
        );
      case 'passage_in':
        return (
          '🏠 Ingresso rilevato',
          _describePassage(event, 'rientrato'),
          false,
        );
      case 'alert':
        return (
          '⚠️ Avviso di sicurezza',
          'Un oggetto è stato rilevato in movimento senza utente associato.',
          true,
        );
      default:
        //Gli eventi "system" non generano notifiche.
        return (null, null, false);
    }
  }

  String _describePassage(EventDto event, String action) {
    try {
      final objects = event.detectedObjects ?? '[]';
      if (objects.contains('"name"')) {
        //Estrai il nome dell'oggetto dal JSON.
        final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(objects);
        if (nameMatch != null) {
          return '"${nameMatch.group(1)}" è $action.';
        }
      }
    } catch (_) {}
    return 'Un oggetto è $action.';
  }
}
