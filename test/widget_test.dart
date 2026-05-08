import 'package:flutter_test/flutter_test.dart';
import 'package:fridge2feast/main.dart';

void main() {
  testWidgets('App loads registration screen', (WidgetTester tester) async {
    await tester.pumpWidget(const Fridge2FeastApp());

    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(
      find.text("Let's get you set up with Fridge2Feast"),
      findsOneWidget,
    );
  });
}