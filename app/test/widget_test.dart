// Test base dell'app GateKeeper.
// Aggiornato per usare GateKeeperApp al posto del vecchio MyApp di default.
//
// TODO: man mano che aggiungi schermate, aggiungi qui test specifici.
// Usa tester.pumpWidget + tester.pump(Duration) per testare animazioni.

import 'package:flutter_test/flutter_test.dart';
import 'package:gatekeeper_app/app.dart';

void main() {
  testWidgets('GateKeeper app smoke test', (WidgetTester tester) async {
    // Monta il widget radice dell'app.
    // pumpWidget avvia il build tree completo: GateKeeperApp → router → shell → dashboard.
    await tester.pumpWidget(const GateKeeperApp());

    // pump() esegue un frame in più per completare animazioni/routing iniziale.
    await tester.pump();

    // Verifica che il titolo GateKeeper sia presente nell'albero dei widget.
    expect(find.text('GateKeeper'), findsWidgets);
  });
}
