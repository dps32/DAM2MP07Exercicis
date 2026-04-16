import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App starts on categories page', (WidgetTester tester) async {
    await tester.pumpWidget(const PaintingsDbApp());

    expect(find.text('Classic Paintings DB - Categories'), findsOneWidget);
  });
}
