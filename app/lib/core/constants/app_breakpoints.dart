/// Breakpoint centralizzati.
///
/// Tenerli in un file dedicato evita numeri "magici" sparsi nel progetto.
abstract final class AppBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1100;
  static const double desktop = 1280;

  // Soglia specifica per objects_screen: più bassa di mobile perché
  // la schermata è già dentro la shell (sidebar 230px tolta dal layout).
  // Sotto questa larghezza i filtri si impilano verticalmente.
  static const double objectsMobile = 500;
}