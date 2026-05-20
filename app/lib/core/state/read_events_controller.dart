import 'package:flutter/foundation.dart';

//Controller singleton che traccia gli ID delle notifiche già lette/risolte.
//Condiviso tra Dashboard (LiveEvents) e pagina Notifiche.
//Questo permette alla Dashboard di aggiornare la lista in tempo reale
//quando l'utente segna come letti gli eventi dalla pagina Notifiche.
class ReadEventsController extends ChangeNotifier {
  ReadEventsController._();
  static final ReadEventsController instance = ReadEventsController._();

  //Set degli ID eventi segnati come letti (solo UI, non persistito).
  final Set<String> _readIds = {};
  //Set degli ID alert risolti (propagato da AlertsPage).
  final Set<String> _resolvedAlertIds = {};

  bool isRead(String id) => _readIds.contains(id);
  bool isAlertResolved(String id) => _resolvedAlertIds.contains(id);

  void markRead(String id) {
    if (_readIds.add(id)) notifyListeners();
  }

  void markAllRead(Iterable<String> ids) {
    final added = ids.where((id) => _readIds.add(id)).isNotEmpty;
    if (added) notifyListeners();
  }

  void markAlertResolved(String id) {
    if (_resolvedAlertIds.add(id)) notifyListeners();
  }

  //Chiamato al logout o factory reset.
  void clear() {
    _readIds.clear();
    _resolvedAlertIds.clear();
    notifyListeners();
  }
}
