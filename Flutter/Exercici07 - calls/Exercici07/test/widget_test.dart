import 'package:exemple0700/app.dart';
import 'package:exemple0700/app_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows drawing app', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppData(),
        child: const App(),
      ),
    );

    expect(find.text('Dibuix IA'), findsOneWidget);
    expect(find.text('Query'), findsOneWidget);
  });
}
