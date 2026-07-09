import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('BitsacApp can be instantiated', (WidgetTester tester) async {
    await tester.pumpWidget(const BitsacApp());
    expect(find.byType(BitsacApp), findsOneWidget);
  });
}
