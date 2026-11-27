import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

    testWidgets('shows support email for a deactivated account', (
      WidgetTester tester,
    ) async {
      await http.runWithClient(
        () async {
          await tester.pumpWidget(createTestWidget());
          await fillLoginForm(tester);
          await submitForm(tester);

          expect(
            find.text(
              'This account has been deactivated. Please contact support for assistance.',
            ),
            findsOneWidget,
          );
          final supportEmail = find.widgetWithText(
            TextButton,
            'gobison.uofm@gmail.com',
          );
          expect(supportEmail, findsOneWidget);
          expect(
            find.descendant(
              of: supportEmail,
              matching: find.byIcon(Icons.email_outlined),
            ),
            findsNothing,
          );
        },
        () => MockClient((request) async {
          expect(request.url.path, endsWith('/api/v1/auth/login'));
          return http.Response('{}', 403);
        }),
      );
    });
  });
}
