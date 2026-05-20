import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/state/notifications_controller.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/gate_event.dart';
import '../../shared/models/smart_object.dart';
import '../api/api_exception.dart';
import '../api/dto.dart';
import '../gatekeeper_api.dart';
import '../repositories/repositories.dart';

//Servizio di polling real-time.
//Controlla periodicamente il backend per nuovi eventi, aggiornamenti utenti
//e dispositivi. Estende ChangeNotifier: le pagine possono chiamare
//`ListenableBuilder(listenable: RealtimeService.instance, ...)` per
//rirenderizzarsi automaticamente quando arrivano dati nuovi.
//
//Il polling usa intervalli brevi (3s) per gli eventi e più lunghi (10s)
//per utenti e oggetti, per bilanciare reattività e carico sul Raspberry.
class RealtimeService extends ChangeNotifier {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  Timer? _eventTimer;
  Timer? _dataTimer;
  bool _running = false;

  //Dati correnti — le pagine leggono questi campi dopo ogni notifica.
  List<GateEvent> events = const [];
  List<AppUser> users = const [];
  List<SmartObject> objects = const [];
  int? _lastKnownEventId;

  //Intervalli di polling più reattivi per un'esperienza vicina al real-time.
  static const _eventInterval = Duration(seconds: 2);
  static const _dataInterval = Duration(seconds: 5);

  bool get isRunning => _running;

  //Avvia il polling. Chiamato dopo il login.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    //Carica dati iniziali subito (non aspettare il primo tick).
    await _loadAll(notify: true);

    _eventTimer = Timer.periodic(_eventInterval, (_) => _pollEvents());
    _dataTimer = Timer.periodic(_dataInterval, (_) => _pollData());

    if (kDebugMode) {
      debugPrint('[Realtime] Avviato');
    }
  }

  //Ferma il polling. Chiamato al logout.
  void stop() {
    _eventTimer?.cancel();
    _dataTimer?.cancel();
    _eventTimer = null;
    _dataTimer = null;
    _running = false;
    _lastKnownEventId = null;
    events = const [];
    users = const [];
    objects = const [];
    if (kDebugMode) {
      debugPrint('[Realtime] Fermato');
    }
  }

  //Forza un reload immediato. Chiamato da pull-to-refresh.
  Future<void> refresh() => _loadAll(notify: true);

  //Carica tutto in parallelo.
  Future<void> _loadAll({bool notify = false}) async {
    try {
      final results = await Future.wait([
        EventsRepository.list().catchError((_) => <GateEvent>[]),
        UsersRepository.list().catchError((_) => <AppUser>[]),
        DevicesRepository.list().catchError((_) => <SmartObject>[]),
      ]);
      final newEvents = results[0] as List<GateEvent>;
      final newUsers = results[1] as List<AppUser>;
      final newObjects = results[2] as List<SmartObject>;

      //Imposta baseline per il poll eventi.
      if (_lastKnownEventId == null && newEvents.isNotEmpty) {
        _lastKnownEventId = newEvents.map((e) => int.tryParse(e.id) ?? 0).reduce((a, b) => a > b ? a : b);
      }

      final changed = _hasChanges(newEvents, newUsers, newObjects);
      events = newEvents;
      users = newUsers;
      objects = newObjects;

      if (notify || changed) {
        notifyListeners();
      }
    } catch (_) {}
  }

  //Poll solo eventi (frequente).
  Future<void> _pollEvents() async {
    if (!_running) return;
    try {
      final dtos = await GateKeeperApi.instance.events.list();
      if (dtos.isEmpty) return;

      final maxId = dtos.map((e) => e.id).reduce((a, b) => a > b ? a : b);
      if (_lastKnownEventId == null) {
        _lastKnownEventId = maxId;
        return;
      }

      final newDtos = dtos.where((e) => e.id > _lastKnownEventId!).toList();
      if (newDtos.isEmpty) return;

      _lastKnownEventId = maxId;

      //Notifica locale per ogni nuovo evento.
      for (final dto in newDtos) {
        await _notifyLocal(dto);
      }

      //Ricarica tutto per aggiornare UI.
      await _loadAll(notify: true);
    } on ApiException catch (_) {
    } catch (_) {}
  }

  //Poll dati (utenti + oggetti) meno frequente.
  Future<void> _pollData() async {
    if (!_running) return;
    await _loadAll(notify: false);
  }

  //Controlla se i dati sono cambiati rispetto a quelli correnti.
  bool _hasChanges(
    List<GateEvent> newEvt,
    List<AppUser> newUsr,
    List<SmartObject> newObj,
  ) {
    if (newEvt.length != events.length) return true;
    if (newUsr.length != users.length) return true;
    if (newObj.length != objects.length) return true;
    //Controlla cambiamenti stato oggetti.
    for (var i = 0; i < newObj.length; i++) {
      if (newObj[i].isInside != objects[i].isInside) return true;
    }
    //Controlla cambiamenti posizione utenti.
    for (var i = 0; i < newUsr.length; i++) {
      if (newUsr[i].isInside != users[i].isInside) return true;
    }
    return false;
  }

  //Mostra notifica locale per un evento rilevante.
  Future<void> _notifyLocal(EventDto event) async {
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

  (String?, String?, bool) _eventToNotification(EventDto event) {
    switch (event.eventType) {
      case 'passage_out':
        return (
          'Uscita rilevata',
          _describePassage(event, 'uscito'),
          false,
        );
      case 'passage_in':
        return (
          'Ingresso rilevato',
          _describePassage(event, 'rientrato'),
          false,
        );
      case 'alert':
        return (
          'Avviso di sicurezza',
          'Oggetto in movimento senza utente associato.',
          true,
        );
      default:
        return (null, null, false);
    }
  }

  String _describePassage(EventDto event, String action) {
    try {
      final objects = event.detectedObjects ?? '[]';
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(objects);
      if (nameMatch != null) return '"${nameMatch.group(1)}" e\' $action.';
    } catch (_) {}
    return 'Un oggetto e\' $action.';
  }
}
