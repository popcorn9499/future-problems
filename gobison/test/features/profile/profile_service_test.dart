import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/network/api_config.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/features/profile/profile_service.dart';

void main() {
  group('ProfileService', () {
    group('updateProfile', () {
      test(
        'sends the correct request and returns the updated profile',
        () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              jsonEncode({
                'userId': '123',
                'firstName': 'Rebekah',
                'lastName': 'Soneye',
                'age': 22,
                'pronouns': 'She/her',
                'description': 'Updated description',
                'avatarColor': '#E9DFD2',
              }),
              200,
            );
          });

          final service = ProfileService(client: client);

          final result = await service.updateProfile(
            changes: {
              'firstName': 'Rebekah',
              'description': 'Updated description',
            },
          );

          expect(capturedRequest.method, 'PATCH');
          expect(
            capturedRequest.url,
            Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/profile'),
          );
          expect(capturedRequest.headers['content-type'], 'application/json');
          expect(capturedRequest.headers['accept'], 'application/json');

          expect(jsonDecode(capturedRequest.body), {
            'firstName': 'Rebekah',
            'description': 'Updated description',
          });

          expect(result, isA<UserProfile>());
          expect(result.userId, '123');
          expect(result.firstName, 'Rebekah');
          expect(result.lastName, 'Soneye');
          expect(result.age, 22);
          expect(result.pronouns, 'She/her');
          expect(result.description, 'Updated description');
          expect(result.avatarColor, '#E9DFD2');
        },
      );

      test('throws an exception when profile update fails', () async {
        final client = MockClient(
          (_) async =>
              http.Response('{"message":"Invalid profile details"}', 400),
        );

        final service = ProfileService(client: client);

        expect(
          () => service.updateProfile(changes: {'firstName': ''}),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('Profile update failed (400)'),
                contains('Invalid profile details'),
              ),
            ),
          ),
        );
      });

      test('throws an exception when the session has expired', () async {
        final client = MockClient(
          (_) async => http.Response('{"message":"Unauthorized"}', 401),
        );

        final service = ProfileService(client: client);

        expect(
          () => service.updateProfile(changes: {'firstName': 'Rebekah'}),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Profile update failed (401)'),
            ),
          ),
        );
      });

      test('throws an exception on a server error', () async {
        final client = MockClient(
          (_) async =>
              http.Response('{"message":"Internal server error"}', 500),
        );

        final service = ProfileService(client: client);

        expect(
          () => service.updateProfile(changes: {'firstName': 'Rebekah'}),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Profile update failed (500)'),
            ),
          ),
        );
      });

      test('throws an exception when the response is not 200', () async {
        final client = MockClient(
          (_) async => http.Response('{"message":"Method not allowed"}', 405),
        );

        final service = ProfileService(client: client);

        expect(
          () => service.updateProfile(changes: {'firstName': 'Rebekah'}),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Profile update failed (405)'),
            ),
          ),
        );
      });
    });
  });
}
