import 'package:flutter_test/flutter_test.dart';
import 'package:karmasetu/main.dart';

void main() {
  testWidgets('KarmaSetu App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KarmaSetuApp());
    expect(find.text('KarmaSetu'), findsOneWidget);
  });
}
