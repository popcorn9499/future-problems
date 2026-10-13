import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/register_page.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(home: RegisterPage());
  }

  group('RegisterPage', () {
    testWidgets('displays all registration fields and buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Join GoBison'), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Last name'), findsOneWidget);
      expect(find.text('University of Manitoba Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsNWidgets(2));
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('rejects an email containing @', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your first name'),
        'Rebekah',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your last name'),
        'Soneye',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your UMNetID'),
        'rebekah@myumanitoba.ca',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'At least 8 characters'),
        'password123',
      );

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

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

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your first name'),
        'Rebekah',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your last name'),
        'Soneye',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your UMNetID'),
        'rebekah123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'At least 8 characters'),
        'short',
      );

      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final passwordField = find.byType(EditableText).last;

      expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();

      expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pumpAndSettle();

      expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);
    });
  });
}
