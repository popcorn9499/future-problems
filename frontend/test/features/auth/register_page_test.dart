import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/presentation/register_page.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(home: RegisterPage());
  }

  Future<void> submitForm(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
  }

  Future<void> fillRegistrationForm(
    WidgetTester tester, {
    String firstName = 'Rebekah',
    String lastName = 'Soneye',
    String email = 'rebekah123',
    String password = 'Password123',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your first name'),
      firstName,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your last name'),
      lastName,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your UMNetID'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Please enter a password'),
      password,
    );
  }

  group('RegisterPage validation', () {
    testWidgets('shows required-field errors when submitted empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await submitForm(tester);

      expect(find.text('This field is required'), findsOneWidget);
      expect(find.text('Please enter your UMNetId'), findsOneWidget);
      expect(find.text('Please enter a password'), findsNWidgets(2));
    });

    testWidgets('rejects a UMNetID containing @ or a domain', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester, email: 'rebekah@myumanitoba.ca');

      await submitForm(tester);

      expect(
        find.text(
          'Enter the UMNetId part of your email only, without @ or a domain',
        ),
        findsOneWidget,
      );
    });

    testWidgets('rejects a password shorter than 8 characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester, password: 'Pass123');
      await submitForm(tester);

      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('rejects a password without an uppercase letter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester, password: 'password123');
      await submitForm(tester);

      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('rejects a password without a lowercase letter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester, password: 'PASSWORD123');
      await submitForm(tester);

      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('rejects a password without a number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester, password: 'PasswordABC');
      await submitForm(tester);

      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('accepts a password meeting all requirements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester, password: 'Password123');
      await submitForm(tester);

      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsNothing,
      );
    });

    testWidgets('accepts valid registration field values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await fillRegistrationForm(tester);
      await submitForm(tester);

      expect(find.text('This field is required'), findsNothing);
      expect(find.text('Please enter your UMNetId'), findsNothing);
      final passwordField = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .last;

      expect(passwordField.validator?.call('Password123'), isNull);
      expect(
        find.text(
          'Enter the UMNetId part of your email only, without @ or a domain',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsNothing,
      );
    });
  });
}
