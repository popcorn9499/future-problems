import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/registration_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final scenarios = <String, String>{
    'duplicate': 'An account with this email already exists.',
    'servererror': "It's not you, it's us. Please try again later.",
  };

  for (final scenario in scenarios.entries) {
    testWidgets('Registration handles ${scenario.key}', (tester) async {
      await openRegistration(tester);

      final fields = <String, String>{
        'Enter your first name': 'Test',
        'Enter your last name': 'User',
        'Enter your UMNetID': scenario.key,
        'Please enter a password': 'TestPass123',
      };

      for (final field in fields.entries) {
        await tester.enterText(
          find.widgetWithText(TextFormField, field.key),
          field.value,
        );
      }

      final button = find.widgetWithText(ElevatedButton, 'Create Account');

      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text(scenario.value), findsOneWidget);
      expect(find.text('Join GoBison'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }
}
