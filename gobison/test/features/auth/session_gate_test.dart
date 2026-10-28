import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:gobison/features/auth/presentation/session_gate.dart';
import 'package:gobison/features/auth/presentation/verification_page.dart';
import 'package:gobison/features/home/presentation/home_page.dart';

void main() {
  setUp(SessionService.clearSession);
  tearDown(SessionService.clearSession);

  testWidgets('no cached user opens login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionGate()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  for (final verified in [false, true]) {
    testWidgets('cached user routes correctly with verified=$verified', (
      tester,
    ) async {
      await SessionService.saveUser(
        user: User(
          id: 'ada@myumanitoba.ca',
          firstName: 'Ada',
          email: 'ada@myumanitoba.ca',
          verified: verified,
        ),
      );
      final session = await SessionService().loadCurrentSession();
      expect(session!.profile.firstName, 'Ada');
      expect(session.profile.age, isNull);
      expect(session.profile.pronouns, isNull);
      expect(session.profile.description, isNull);
      await tester.pumpWidget(const MaterialApp(home: SessionGate()));
      await tester.pumpAndSettle();
      expect(
        find.byType(verified ? HomePage : VerificationPage),
        findsOneWidget,
      );
    });
  }
}
