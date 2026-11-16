import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/features/auth/auth_service.dart';
import 'package:gobison/features/auth/presentation/verification_page.dart';
import 'package:gobison/features/home/presentation/home_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await SessionService.clearSession();

    await AuthService().login(
      email: 'integrationtest@myumanitoba.ca',
      password: 'TestPass123',
    );
    final user = await AuthService().currentUser();
    expect(user!['verified'], isFalse);
  });

  tearDown(SessionService.clearSession);

  testWidgets('Incorrect verification code shows an error', (tester) async {
    const user = User(
      id: 'integration-user',
      firstName: 'Test',
      lastName: 'User',
      email: 'integrationtest@myumanitoba.ca',
      verified: false,
    );

    const profile = UserProfile(
      userId: 'integration-user',
      firstName: 'Test',
      lastName: 'User',
    );

    await SessionService.saveSession(user: user, profile: profile);

    await tester.pumpWidget(
      const MaterialApp(
        home: VerificationPage(
          email: 'integrationtest@myumanitoba.ca',
          user: user,
          userProfile: profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));

    const code = '111111';

    for (var i = 0; i < code.length; i++) {
      final field = fields.at(i);

      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      await tester.enterText(field, code[i]);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        tester.widget<TextField>(field).controller!.text,
        code[i],
        reason: 'Verification field ${i + 1} should contain its digit',
      );
    }

    final enteredCode = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .join();

    expect(enteredCode, code);

    final error = find.text('The verification code is incorrect.');

    for (var attempt = 0; attempt < 50 && error.evaluate().isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(error, findsOneWidget);
    expect(find.byType(VerificationPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    expect(SessionService.cachedSession!.user.verified, isFalse);
    final session = await SessionService().loadCurrentSession();
    expect(session?.user.verified, isFalse);
  });

  testWidgets('Correct verification code opens the home page', (tester) async {
    const user = User(
      id: 'integration-user',
      firstName: 'Test',
      lastName: 'User',
      email: 'integrationtest@myumanitoba.ca',
      verified: false,
    );

    const profile = UserProfile(
      userId: 'integration-user',
      firstName: 'Test',
      lastName: 'User',
    );

    await SessionService.saveSession(user: user, profile: profile);

    await tester.pumpWidget(
      const MaterialApp(
        home: VerificationPage(
          email: 'integrationtest@myumanitoba.ca',
          user: user,
          userProfile: profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));

    const code = '123456';

    for (var i = 0; i < code.length; i++) {
      final field = fields.at(i);

      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      await tester.enterText(field, code[i]);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    final home = find.byType(HomePage);

    for (var attempt = 0; attempt < 50 && home.evaluate().isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(home, findsOneWidget);
    expect(find.byType(VerificationPage), findsNothing);
    expect(find.text('Your next ride starts here.'), findsOneWidget);

    expect(SessionService.cachedSession!.user.verified, isTrue);
    final session = await SessionService().loadCurrentSession();
    expect(session?.user.id, user.id);
    expect(session?.user.verified, isTrue);
  });
}
