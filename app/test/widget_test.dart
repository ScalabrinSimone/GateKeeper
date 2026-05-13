import 'package:flutter_test/flutter_test.dart';
import 'package:gatekeeper_app/app.dart';
import 'package:gatekeeper_app/core/state/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    //Inizializza SharedPreferences in-memory per i test.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('GateKeeper app smoke test', (WidgetTester tester) async {
    final settings = SettingsController();
    await settings.load();

    await tester.pumpWidget(GateKeeperApp(settings: settings));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dashboard'), findsWidgets);
  });
}
