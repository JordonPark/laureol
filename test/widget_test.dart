import 'package:flutter_test/flutter_test.dart';
import 'package:laureol/main.dart';

void main() {
  testWidgets('Shows the game title on launch', (tester) async {
    await tester.pumpWidget(const LaureolApp());

    expect(find.text('라우럴! 볼륨 좀 올려'), findsOneWidget);
  });
}
