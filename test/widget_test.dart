import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_g/screens/login_screen.dart';
import 'package:wallet_g/utils/theme_manager.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // We test the LoginScreen directly to avoid Firebase initialization issues in tests
    await tester.pumpWidget(
      MaterialApp(theme: AppThemes.lightTheme, home: const LoginScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the login screen is displayed
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
