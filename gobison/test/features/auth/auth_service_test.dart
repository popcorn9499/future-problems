import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/network/api_config.dart';
import 'package:gobison/features/auth/auth_service.dart';

void main() {
  group('AuthService', () {
    group('register', () {
      test(
        'sends the correct request and returns successful response',
        () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              jsonEncode({
                'id': '123',
                'firstName': 'Rebekah',
                'lastName': 'Soneye',
                'email': 'rebekah123@myumanitoba.ca',
              }),
              201,
            );
          });

          final service = AuthService(client: client);

          final result = await service.register(
            firstName: 'Rebekah',
            lastName: 'Soneye',
            email: 'rebekah123@myumanitoba.ca',
            password: 'password123',
          );

          expect(capturedRequest.method, 'POST');
          expect(
            capturedRequest.url,
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/register'),
          );
          expect(capturedRequest.headers['content-type'], 'application/json');
          expect(capturedRequest.headers['accept'], 'application/json');

          expect(jsonDecode(capturedRequest.body), {
            'firstName': 'Rebekah',
            'lastName': 'Soneye',
            'email': 'rebekah123@myumanitoba.ca',
            'password': 'password123',
          });

          expect(result['id'], '123');
          expect(result['firstName'], 'Rebekah');
          expect(result['email'], 'rebekah123@myumanitoba.ca');
        },
      );

      test('accepts a 200 response', () async {
        final client = MockClient(
          (_) async => http.Response('{"success": true}', 200),
        );

        final service = AuthService(client: client);

        final result = await service.register(
          firstName: 'Rebekah',
          email: 'rebekah123',
          password: 'password123',
        );

        expect(result['success'], isTrue);
      });

      test('throws an exception when registration fails', () async {
        final client = MockClient(
          (_) async =>
              http.Response('{"message":"Email already registered"}', 409),
        );

        final service = AuthService(client: client);

        expect(
          () => service.register(
            firstName: 'Rebekah',
            email: 'rebekah123',
            password: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('Registration failed (409)'),
                contains('Email already registered'),
              ),
            ),
          ),
        );
      });
    });

    test('current user sends a GET and handles session responses', () async {
      final service = AuthService(client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'));
        return http.Response('{"userId":"ada","verified":true}', 200);
      }));
      expect((await service.currentUser())!['userId'], 'ada');
      final signedOut = AuthService(client: MockClient((_) async => http.Response('', 401)));
      expect(await signedOut.currentUser(), isNull);
      final failed = AuthService(client: MockClient((_) async => http.Response('', 500)));
      expect(failed.currentUser(), throwsException);
    });
    group('login', () {
      test(
        'sends the correct request and returns successful response',
        () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              '{"userId":"123","email":"rebekah123@myumanitoba.ca"}',
              200,
            );
          });

          final service = AuthService(client: client);

          final result = await service.login(
            email: 'rebekah123@myumanitoba.ca',
            password: 'password123',
          );

          expect(capturedRequest.method, 'POST');
          expect(
            capturedRequest.url,
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login'),
          );

          expect(jsonDecode(capturedRequest.body), {
            'email': 'rebekah123@myumanitoba.ca',
            'password': 'password123',
          });

          expect(result['userId'], '123');
          expect(result['email'], 'rebekah123@myumanitoba.ca');
        },
      );

      test('throws an exception when login fails', () async {
        final client = MockClient(
          (_) async => http.Response('{"message":"Invalid credentials"}', 401),
        );

        final service = AuthService(client: client);

        expect(
          () => service.login(
            email: 'rebekah123@myumanitoba.ca',
            password: 'wrongpassword',
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('Login failed (401)'),
                contains('Invalid credentials'),
              ),
            ),
          ),
        );
      });
    });

    group('AuthService.verifyEmail', () {
      test('sends correct request with headers and body, returning decoded response on success', () async {
        late http.Request capturedRequest;

        final client = MockClient((request) async {
          capturedRequest = request;

          return http.Response('{"universityVerified": true}', 200);
        });

        final service = AuthService(client: client);

        final result = await service.verifyEmail(code: '654321');

        expect(capturedRequest.method, 'POST');
        expect(
          capturedRequest.url,
          Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/verify-email'),
        );
        expect(capturedRequest.headers['Content-Type'], 'application/json');
        expect(capturedRequest.headers['Accept'], 'application/json');
        expect(capturedRequest.headers['Authorization'], isNull);

        expect(jsonDecode(capturedRequest.body), {'code': '654321'});

        expect(result['universityVerified'], true);
      });

      test('throws exception when verification fails with a non-200/201 status code', () async {
        final client = MockClient((request) async {
          return http.Response('Invalid verification code', 400);
        });

        final service = AuthService(client: client);

        expect(
          () => service.verifyEmail(code: '000000'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains(
                'Account verification failed (400): Invalid verification code',
              ),
            ),
          ),
        );
      });
    });
  });
}
