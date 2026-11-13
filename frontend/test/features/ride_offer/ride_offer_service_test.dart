import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gobison/core/network/api_config.dart';
import 'package:gobison/features/ride_offer/ride_offer_service.dart';

void main() {
  group('RideOfferService', () {

    group('createRideOffer', () {
      test(
        'sends the correct request and returns the created ride offer',
        () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              jsonEncode({
                'id': 'ride123',
                'rideType': 'arriving',
                'userId': '123',
                'city': 'Fargo',
                'streetAddress': '123 Main Street',
                'arrivalTime': '08:30',
                'departureTime': null,
                'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
                'passengerNum': 3,
                'description': 'Morning commute',
                'askingForDrivers': false,
              }),
              200,
            );
          });

          final service = RideOfferService(client: client);

          final result = await service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            departureTime: null,
            passengerNum: 3,
            daysOfWeek: ['Monday', 'Wednesday', 'Friday'],
            description: 'Morning commute',
            askingForDrivers: false,
          );

          expect(capturedRequest.method, 'POST');

          expect(
            capturedRequest.url,
            Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/rides/offers',
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
            'rideType': 'arriving',
            'city': 'Fargo',
            'streetAddress': '123 Main Street',
            'arrivalTime': '08:30',
            'departureTime': null,
            'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
            'passengerNum': 3,
            'description': 'Morning commute',
            'askingForDrivers': false,
          });

          expect(result, isA<Map<String, dynamic>>());
          expect(result['id'], 'ride123');
          expect(result['rideType'], 'arriving');
          expect(result['userId'], '123');
          expect(result['city'], 'Fargo');
          expect(result['streetAddress'], '123 Main Street');
          expect(result['arrivalTime'], '08:30');
          expect(result['departureTime'], null);
          expect(
            result['daysOfWeek'],
            ['Monday', 'Wednesday', 'Friday'],
          );
          expect(result['passengerNum'], 3);
          expect(result['description'], 'Morning commute');
          expect(result['askingForDrivers'], false);
        },
      );

      test('successfully creates a ride offer when the response status is 201', () async {
          final client = MockClient(
            (_) async => http.Response(
              jsonEncode({
                'id': 'ride456',
                'userId': '123',
                'city': 'Fargo',
              }),
              201,
            ),
          );

          final service = RideOfferService(client: client);

          final result = await service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '456 University Drive',
            arrivalTime: '09:00',
            departureTime: null,
            passengerNum: 2,
            daysOfWeek: ['Tuesday'],
            askingForDrivers: true,
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result['id'], 'ride456');
          expect(result['city'], 'Fargo');
        },
      );

      test('sends null description when no description is provided', () async {
          late http.Request capturedRequest;

          final client = MockClient((request) async {
            capturedRequest = request;

            return http.Response(
              jsonEncode({'id': 'ride789'}),
              200,
            );
          });

          final service = RideOfferService(client: client);

          await service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '789 Oak Street',
            arrivalTime: '07:30',
            departureTime: null,
            passengerNum: 1,
            daysOfWeek: ['Monday'],
            askingForDrivers: true,
          );

          final requestBody = jsonDecode(capturedRequest.body);

          expect(requestBody['description'], isNull);
          expect(requestBody['userId'], '123');
          expect(requestBody['passengerNum'], 1);
        },
      );

      test('throws an exception when ride offer creation fails (400)', () async {
        final client = MockClient(
          (_) async => http.Response(
            '{"message":"Invalid ride offer details"}',
            400,
          ),
        );

        final service = RideOfferService(client: client);

        expect(
          () => service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            departureTime: null,
            passengerNum: 3,
            daysOfWeek: ['Monday'],
            askingForDrivers: true,
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('Ride offer creation failed (400)'),
                contains('Invalid ride offer details'),
              ),
            ),
          ),
        );
      });

      test('throws an exception when the session has expired (401)', () async {
        final client = MockClient(
          (_) async => http.Response(
            '{"message":"Unauthorized"}',
            401,
          ),
        );

        final service = RideOfferService(client: client);

        expect(
          () => service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            departureTime: null,
            passengerNum: 3,
            daysOfWeek: ['Monday'],
            askingForDrivers: true,
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Ride offer creation failed (401)'),
            ),
          ),
        );
      });

      test('throws an exception on a server error (500)', () async {
        final client = MockClient(
          (_) async => http.Response(
            '{"message":"Internal server error"}',
            500,
          ),
        );

        final service = RideOfferService(client: client);

        expect(
          () => service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            departureTime: null,
            passengerNum: 3,
            daysOfWeek: ['Monday'],
            askingForDrivers: true,
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Ride offer creation failed (500)'),
            ),
          ),
        );
      });

      test('throws an exception when the response status is 405',
          () async {
        final client = MockClient(
          (_) async => http.Response(
            '{"message":"Method not allowed"}',
            405,
          ),
        );

        final service = RideOfferService(client: client);

        expect(
          () => service.createRideOffer(
            userId: '123',
            rideType: 'arriving',
            city: 'Fargo',
            streetAddress: '123 Main Street',
            arrivalTime: '08:30',
            departureTime: null,
            passengerNum: 3,
            daysOfWeek: ['Monday'],
            askingForDrivers: true,
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Ride offer creation failed (405)'),
            ),
          ),
        );
      });
    });
  });
}
