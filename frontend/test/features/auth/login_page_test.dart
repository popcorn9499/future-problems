import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(home: LoginPage());
  }

  Future<void> submitForm(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  Future<void> fillLoginForm(
    WidgetTester tester, {
    String email = 'rebekah123',
    String password = 'password123',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your UMNetID'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      password,
    );
  }

  group('LoginPage validation', () {
    testWidgets('shows required-field errors when submitted empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await submitForm(tester);

      expect(find.text('This field is required'), findsNWidgets(2));
    });

    testWidgets('accepts valid login field values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillLoginForm(tester);

      await submitForm(tester);

      expect(find.text('This field is required'), findsNothing);
    });
  });
}
