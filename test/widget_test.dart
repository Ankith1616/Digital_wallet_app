import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_g/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalWalletApp());

    // Verify that the login screen is displayed
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
