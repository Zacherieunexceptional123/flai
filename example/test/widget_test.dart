import 'package:flutter_test/flutter_test.dart';
import 'package:flai_example/main.dart';

void main() {
  testWidgets('FlAI showcase app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FlaiShowcaseApp());
    expect(find.text('FlAI Chat'), findsOneWidget);
  });
}
