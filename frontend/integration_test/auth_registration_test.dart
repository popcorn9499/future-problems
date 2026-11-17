import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/registration_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Signed-out app opens login and can navigate to registration', (
    tester,
  ) async {
    await openRegistration(tester);

    expect(find.text('Join GoBison'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('Empty registration form shows required errors', (tester) async {
    await openRegistration(tester);

    final createAccountButton = find.widgetWithText(
      ElevatedButton,
      'Create Account',
    );

    await tester.ensureVisible(createAccountButton);
    await tester.pumpAndSettle();
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    final errors = tester
        .widgetList<InputDecorator>(find.byType(InputDecorator))
        .map((field) => field.decoration.errorText)
        .whereType<String>()
        .toList();

    expect(
      errors,
      unorderedEquals([
        'This field is required',
        'Please enter your UMNetId',
        'Please enter a password',
      ]),
    );
  });

  testWidgets('Registration rejects a full email address', (tester) async {
    await openRegistration(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your first name'),
      'Test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your UMNetID'),
      'integrationtest@myumanitoba.ca',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Please enter a password'),
      'TestPass123',
    );

    final createAccountButton = find.widgetWithText(
      ElevatedButton,
      'Create Account',
    );

    await tester.ensureVisible(createAccountButton);
    await tester.pumpAndSettle();
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Enter the UMNetId part of your email only, without @ or a domain',
      ),
      findsOneWidget,
    );
  });

  final invalidPasswords = <String, String>{
    'too short': 'Abc1234',
    'missing uppercase': 'abcdefgh1',
    'missing lowercase': 'ABCDEFGH1',
    'missing number': 'Abcdefgh',
  };

  for (final entry in invalidPasswords.entries) {
    testWidgets('Registration rejects password: ${entry.key}', (tester) async {
      await openRegistration(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your first name'),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your UMNetID'),
        'integrationtest',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Please enter a password'),
        entry.value,
      );

      final createAccountButton = find.widgetWithText(
        ElevatedButton,
        'Create Account',
      );

      await tester.ensureVisible(createAccountButton);
      await tester.pumpAndSettle();
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
        ),
        findsOneWidget,
      );
    });
  }
}
