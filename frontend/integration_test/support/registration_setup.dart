import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:gobison/features/auth/presentation/register_page.dart';
import 'package:gobison/main.dart' as app;

Future<void> openRegistration(WidgetTester tester) async {
  // Start a fresh widget tree so a previous test's route is not reused.
  await tester.pumpWidget(const SizedBox.shrink());
  app.main();
  for (
    var attempt = 0;
    attempt < 100 && find.byType(LoginPage).evaluate().isEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(LoginPage), findsOneWidget);
  final signUp = find.widgetWithText(TextButton, ' Sign Up');
  await tester.ensureVisible(signUp);
  await tester.tap(signUp);
  await tester.pumpAndSettle();
  expect(find.byType(RegisterPage), findsOneWidget);
}
