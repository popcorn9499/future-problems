import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/features/auth/auth_service.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:gobison/features/auth/presentation/session_gate.dart';
import 'package:gobison/features/auth/presentation/verification_page.dart';
import 'package:gobison/features/home/presentation/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(SessionService.clearSession);
  tearDown(SessionService.clearSession);

  SessionService service(http.Response response) => SessionService(
    authService: AuthService(client: MockClient((_) async => response)),
  );

  testWidgets('missing session opens login', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SessionGate(sessionService: service(http.Response('', 401)))));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('401 clears a previously cached session', (tester) async {
    await SessionService.saveSession(
      accessToken: 'old-token',
      user: const User(id: 'old', firstName: 'Old', email: 'old@example.com', verified: true),
      profile: const UserProfile(userId: 'old', firstName: 'Old', age: 25),
    );
    expect(SessionService.cachedSession, isNotNull);
    await tester.pumpWidget(MaterialApp(home: SessionGate(sessionService: service(http.Response('', 401)))));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(SessionService.cachedSession, isNull);
    expect(SessionService.accessToken, isNull);
    // A different user must not inherit the previous user's cached profile.
    final restored = await service(http.Response(jsonEncode({
      'userId': 'new', 'firstName': 'New', 'email': 'new@example.com', 'verified': true,
    }), 200)).loadCurrentSession();
    expect(restored!.profile.userId, 'new');
    expect(restored.profile.age, isNull);
  });

  for (final verified in [false, true]) {
    testWidgets('empty memory restores directly through gate with verified=$verified', (tester) async {
      expect(SessionService.cachedSession, isNull);
      final sessionService = service(http.Response(jsonEncode({
        'userId': 'ada@myumanitoba.ca', 'firstName': 'Ada', 'lastName': 'Lovelace',
        'email': 'ada@myumanitoba.ca', 'verified': verified,
      }), 200));
      await tester.pumpWidget(MaterialApp(home: SessionGate(sessionService: sessionService)));
      await tester.pumpAndSettle();
      expect(find.byType(verified ? HomePage : VerificationPage), findsOneWidget);
      expect(SessionService.cachedSession!.user.email, 'ada@myumanitoba.ca');
    });

    testWidgets('restored session routes correctly with verified=$verified', (tester) async {
      final sessionService = service(http.Response(jsonEncode({
        'userId': 'ada@myumanitoba.ca', 'firstName': 'Ada', 'lastName': 'Lovelace',
        'email': 'ada@myumanitoba.ca', 'verified': verified,
      }), 200));
      final session = await sessionService.loadCurrentSession();
      expect(session!.profile.firstName, 'Ada');
      expect(session.profile.age, isNull);
      expect(session.profile.gender, isNull);
      expect(session.profile.description, isNull);
      await tester.pumpWidget(MaterialApp(home: SessionGate(sessionService: sessionService)));
      await tester.pumpAndSettle();
      expect(find.byType(verified ? HomePage : VerificationPage), findsOneWidget);
    });
  }

  testWidgets('server failure offers retry instead of login', (tester) async {
    var requests = 0;
    final sessionService = SessionService(authService: AuthService(client: MockClient((_) async {
      requests++;
      if (requests == 1) return http.Response('', 500);
      return http.Response(jsonEncode({
        'userId': 'ada', 'firstName': 'Ada', 'lastName': 'Lovelace', 'email': 'ada@example.com', 'verified': true,
      }), 200);
    })));
    await tester.pumpWidget(MaterialApp(home: SessionGate(sessionService: sessionService)));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load your account.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Unable to load your account.'), findsNothing);
    expect(find.text('Try again'), findsNothing);
  });
}
