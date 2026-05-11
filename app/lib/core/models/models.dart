// ── Barrel file per i modelli ──────────────────────────────────────────────
//
// Un barrel file raccoglie tutti gli export di una cartella in un unico file.
// Invece di scrivere tre import separati per ogni modello, basta:
//
//   import 'package:gatekeeper_app/core/models/models.dart';
//
// e hai accesso a GkUser, RfidObject, GateEvent e tutti gli enum.

export 'gk_user.dart';
export 'rfid_object.dart';
export 'gate_event.dart';
