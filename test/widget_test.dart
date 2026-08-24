import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_world/main.dart';

void main() {
  testWidgets('AI World app starts', (WidgetTester tester) async {
    final cameras = await availableCameras();

    await tester.pumpWidget(AIWorldApp(cameras: cameras));

    expect(find.text('AI WORLD'), findsOneWidget);
  });
}
