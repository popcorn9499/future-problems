import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/features/auth/auth_controller.dart';
import 'package:gobison/features/auth/auth_service.dart';

class FakeAuthService extends AuthService {
  FakeAuthService()
    : super(
        client: MockClient((_) async {
          return http.Response('{}', 200);
        }),
      );

  Future<Map<String, dynamic>> Function()? onRegister;
  Future<Map<String, dynamic>> Function()? onLogin;
  Future<Map<String, dynamic>> Function()? onVerifyEmail;

  @override
  Future<Map<String, dynamic>> register({
    required String firstName,
    String lastName = '',
    required String email,
    required String password,
  }) {
    return onRegister!();
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return onLogin!();
  }

  @override
  Future<Map<String, dynamic>> verifyEmail({required String code}) {
    return onVerifyEmail!();
  }
}

void main() {
  group('AuthController', () {
    late FakeAuthService authService;
    late AuthController controller;

    setUp(() {
      authService = FakeAuthService();
      controller = AuthController(authService);
    });

    tearDown(() {
      controller.dispose();
      SessionService.clearSession();
    });

    test('register stores the user after success', () async {
      authService.onRegister = () async => {
        'id': '123',
        'firstName': 'Rebekah',
        'lastName': 'Soneye',
        'email': 'rebekah123@myumanitoba.ca',
        'createdAt': '2026-10-18T12:00:00Z',
      };

      await controller.register(
        firstName: 'Rebekah',
        lastName: 'Soneye',
        email: 'rebekah123@myumanitoba.ca',
        password: 'password123',
      );

      expect(controller.registeredUser, isA<User>());
      expect(controller.registeredUser!.id, '123');
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('register displays an error when registration fails', () async {
      authService.onRegister = () async {
        throw Exception('Registration failed (409): Email already registered');
      };

      await controller.register(
        firstName: 'Rebekah',
        email: 'rebekah123@myumanitoba.ca',
        password: 'password123',
      );

      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage, isNotEmpty);
      expect(controller.isLoading, isFalse);
    });

    test(
      'login succeeds without an access token and preserves verified status',
      () async {
        authService.onLogin = () async => {
          'user': {
            'userId': '123',
            'firstName': 'Ada',
            'lastName': null,
            'email': 'ada@myumanitoba.ca',
            'verified': true,
          },
        };
        await controller.login(
          email: 'ada@myumanitoba.ca',
          password: 'password',
        );
        expect(controller.errorMessage, isNull);
        final session = await SessionService().loadCurrentSession();
        expect(session!.user.id, '123');
        expect(session.user.verified, isTrue);
      },
    );

    test('login displays an error when login fails', () async {
      authService.onLogin = () async {
        throw Exception('Login failed (401): Invalid credentials');
      };

      await controller.login(
        email: 'rebekah123@myumanitoba.ca',
        password: 'wrongpassword',
      );

      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage, isNotEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while registration is in progress', () async {
      final completer = Completer<Map<String, dynamic>>();

      authService.onRegister = () => completer.future;

      final future = controller.register(
        firstName: 'Rebekah',
        email: 'rebekah123@myumanitoba.ca',
        password: 'password123',
      );

      expect(controller.isLoading, isTrue);

      completer.complete({
        'id': '123',
        'firstName': 'Rebekah',
        'lastName': 'Soneye',
        'email': 'rebekah123@myumanitoba.ca',
        'createdAt': '2026-10-18T12:00:00Z',
      });

      await future;

      expect(controller.isLoading, isFalse);
    });

    test('notifies listeners when registration starts and finishes', () async {
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      authService.onRegister = () async => {
        'id': '123',
        'firstName': 'Rebekah',
        'lastName': 'Soneye',
        'email': 'rebekah123@myumanitoba.ca',
        'createdAt': '2026-10-18T12:00:00Z',
      };

      await controller.register(
        firstName: 'Rebekah',
        email: 'rebekah123@myumanitoba.ca',
        password: 'password123',
      );

      expect(notificationCount, 2);
    });

    test('verifyEmail displays an error when verification fails', () async {
      authService.onVerifyEmail = () async {
        throw Exception(
          'Account verification failed (400): Invalid verification code',
        );
      };

      await controller.emailVerification(code: '000000');

      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage, isNotEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while email verification is in progress', () async {
      final completer = Completer<Map<String, dynamic>>();

      authService.onVerifyEmail = () => completer.future;

      final future = controller.emailVerification(code: '123456');

      expect(controller.isLoading, isTrue);

      await SessionService.saveUser(
        user: const User(
          id: '123',
          firstName: 'Ada',
          email: 'ada@myumanitoba.ca',
        ),
      );
      completer.complete({'universityVerified': true});

      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect((await SessionService().loadCurrentSession())!.user.verified, isTrue);
    });
  });

  group('extractErrorCode', () {
    test('extracts supported HTTP status codes', () {
      expect(extractErrorCode(Exception('Request failed (400)')), 400);
      expect(extractErrorCode(Exception('Request failed (409)')), 409);
      expect(extractErrorCode(Exception('Request failed (429)')), 429);
      expect(extractErrorCode(Exception('Request failed (500)')), 500);
      expect(extractErrorCode(Exception('Request failed (503)')), 503);
    });

    test('returns -1 for an unsupported status code', () {
      expect(extractErrorCode(Exception('Request failed (402)')), -1);
    });
  });
}
