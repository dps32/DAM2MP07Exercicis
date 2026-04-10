// Test de humo rapido para comprobar que el flujo base del contador responde.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Aqui iria el pumpWidget real cuando tengamos UI conectada.
    // await tester.pumpWidget(const MyApp());

    // Comprobamos estado inicial.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Simulamos tap en el boton + y refrescamos frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Validamos que realmente subio a 1.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
