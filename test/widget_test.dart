import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Sales OS app starts', (tester) async {
    await tester.pumpWidget(const SalesOsApp());

    expect(find.text('Sales OS'), findsOneWidget);
  });
}
