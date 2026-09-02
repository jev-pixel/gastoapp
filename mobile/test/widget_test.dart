// Basic smoke test: confirms the app boots and renders the login screen
// without throwing, since GastoApp's initialRoute is '/login'.

import 'package:flutter_test/flutter_test.dart';
import 'package:gastoapp/main.dart';

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GastoApp());
    await tester.pump();

    // LoginScreen renders the app name as a heading.
    expect(find.text('GastoApp'), findsWidgets);
  });
}