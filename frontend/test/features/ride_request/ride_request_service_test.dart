
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/network/api_config.dart';
import 'package:gobison/features/ride_request/ride_request_service.dart';

void main() {
  group('RideRequestService', () {

    group('createRideRequest', () {
      test(
        'sends the correct request and returns the created ride request',
        () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              jsonEncode({
                'id': 'request123',
                'userId': '123',
                'city': 'Fargo',
                'streetAddress': '123 Main Street',
                'arrivalTime': '08:30',
                'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
                'description': 'Looking for a morning ride',
              }),
              200,
            );
          });

          final service = RideRequestService(client: client);

          final result = await service.createRideRequest(
            userId: '123',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            daysOfWeek: ['Monday', 'Wednesday', 'Friday'],
            description: 'Looking for a morning ride',
          );

          expect(capturedRequest.method, 'POST');

          expect(
            capturedRequest.url,
            Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/rides/requests',
            ),
          );

          expect(
            capturedRequest.headers['content-type'],
            'application/json',
          );
          expect(
            capturedRequest.headers['accept'],
            'application/json',
          );

          expect(jsonDecode(capturedRequest.body), {
            'userId': '123',
            'city': 'Fargo',
            'streetAddress': '123 Main Street',
            'arrivalTime': '08:30',
            'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
            'description': 'Looking for a morning ride',
          });

          expect(result, isA<Map<String, dynamic>>());
          expect(result['id'], 'request123');
          expect(result['userId'], '123');
          expect(result['city'], 'Fargo');
          expect(result['streetAddress'], '123 Main Street');
          expect(result['arrivalTime'], '08:30');
          expect(result['daysOfWeek'], ['Monday', 'Wednesday', 'Friday'],);
          expect(result['description'], 'Looking for a morning ride',);
        },
      );

      test(
        'successfully creates a ride request when the response status is 201',
        () async {
          final client = MockClient(
            (_) async => http.Response(
              jsonEncode({
                'id': 'request456',
                'userId': '123',
                'city': 'Fargo',
              }),
              201,
            ),
          );

          final service = RideRequestService(client: client);

          final result = await service.createRideRequest(
            userId: '123',
            city: 'Fargo',
            streetAddress: '456 University Drive',
            arrivalTime: '09:00',
            daysOfWeek: ['Tuesday', 'Thursday'],
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result['id'], 'request456');
          expect(result['city'], 'Fargo');
        },
      );

      test(
        'sends null description when no description is provided',
        () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              jsonEncode({'id': 'request789'}),
              200,
            );
          });

          final service = RideRequestService(client: client);

          await service.createRideRequest(
            userId: '123',
            city: 'Fargo',
            streetAddress: '789 Oak Street',
            arrivalTime: '07:30',
            daysOfWeek: ['Monday'],
          );

          final requestBody = jsonDecode(capturedRequest.body);

          expect(requestBody['description'], isNull);
          expect(requestBody['userId'], '123');
          expect(requestBody['city'], 'Fargo');
          expect(requestBody['daysOfWeek'], ['Monday']);
        },
      );

      test(
        'throws an exception when ride request creation fails (400)',
        () async {
          final client = MockClient(
            (_) async => http.Response(
              '{"message":"Invalid ride request details"}',
              400,
            ),
          );

          final service = RideRequestService(client: client);

          expect(
            () => service.createRideRequest(
              userId: '123',
              city: 'Fargo',
              streetAddress: '123 Main Street',
              arrivalTime: '08:30',
              daysOfWeek: ['Monday'],
            ),
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                allOf(
                  contains('Ride request creation failed (400)'),
                  contains('Invalid ride request details'),
                ),
              ),
            ),
          );
        },
      );

      test(
        'throws an exception when the session has expired (401)',
        () async {
          final client = MockClient(
            (_) async => http.Response(
              '{"message":"Unauthorized"}',
              401,
            ),
          );

          final service = RideRequestService(client: client);

          expect(
            () => service.createRideRequest(
              userId: '123',
              city: 'Fargo',
              streetAddress: '123 Main Street',
              arrivalTime: '08:30',
              daysOfWeek: ['Monday'],
            ),
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                contains('Ride request creation failed (401)'),
              ),
            ),
          );
        },
      );

      test('throws an exception on a server error (500)', () async {
        final client = MockClient(
          (_) async => http.Response(
            '{"message":"Internal server error"}',
            500,
          ),
        );

        final service = RideRequestService(client: client);

        expect(
          () => service.createRideRequest(
            userId: '123',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            daysOfWeek: ['Monday'],
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Ride request creation failed (500)'),
            ),
          ),
        );
      });

      test(
        'throws an exception when the response status is 405',
        () async {
          final client = MockClient(
            (_) async => http.Response(
              '{"message":"Method not allowed"}',
              405,
            ),
          );

          final service = RideRequestService(client: client);

          expect(
            () => service.createRideRequest(
              userId: '123',
              city: 'Fargo',
              streetAddress: '123 Main Street',
              arrivalTime: '08:30',
              daysOfWeek: ['Monday'],
            ),
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                contains('Ride request creation failed (405)'),
              ),
            ),
          );
        },
      );
    });
  });
}
