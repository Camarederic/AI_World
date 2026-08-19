import 'package:flutter_test/flutter_test.dart';
import 'package:ai_world/main.dart';

void main() {
  testWidgets('AI World home page test', (WidgetTester tester) async {
    await tester.pumpWidget(const AIWorldApp());

    expect(find.text('AI World'), findsOneWidget);
    expect(find.text('Я готов увидеть мир'), findsOneWidget);
    expect(find.text('Открыть камеру'), findsOneWidget);
    expect(find.text('Спросить голосом'), findsOneWidget);
  });
}
