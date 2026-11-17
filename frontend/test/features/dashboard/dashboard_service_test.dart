import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/network/api_config.dart';
import 'package:gobison/features/dashboard/dashboard_service.dart';

const _listingId = '3f2b8c1e-0000-4000-8000-000000000001';
const _otherLegId = '3f2b8c1e-0000-4000-8000-000000000002';
const _roundTripId = '3f2b8c1e-0000-4000-8000-0000000000aa';

/// A one-way arrival ride: no departure time, no round trip.
Map<String, dynamic> _arrivalJson() => {
  'id': 1,
  'listingId': _listingId,
  'roundTripId': null,
  'rideType': 'ARRIVAL',
  'origin': 'Steinbach',
  'destination': 'University of Manitoba',
  'arrivalTime': '08:30',
  'departureTime': null,
  'daysOfWeek': ['MONDAY', 'WEDNESDAY'],
  'status': 'OPEN',
  'createdByCurrentUser': true,
  'drivers': [
    {'id': 'dana@myumanitoba.ca', 'firstName': 'Dana', 'lastName': 'Driver'},
  ],
  'passengers': [
    {'id': 'pat@myumanitoba.ca', 'firstName': 'Pat', 'lastName': 'Passenger'},
  ],
};

/// The two legs of one round-trip agreement: same agreement id, same people,
/// different listing ids.
List<Map<String, dynamic>> _roundTripJson() => [
  {
    ..._arrivalJson(),
    'listingId': _listingId,
    'roundTripId': _roundTripId,
    'rideType': 'ARRIVAL',
  },
  {
    ..._arrivalJson(),
    'listingId': _otherLegId,
    'roundTripId': _roundTripId,
    'rideType': 'DEPARTURE',
    'origin': 'University of Manitoba',
    'destination': 'Steinbach',
    'arrivalTime': null,
    'departureTime': '16:15',
  },
];

DashboardService _serviceReturning(http.Response Function() respond) {
  return DashboardService(
    client: MockClient((request) async => respond()),
  );
}

void main() {
  group('DashboardService', () {
    group('fetchAgreements', () {
      test('sends a GET to the dashboard endpoint asking for JSON', () async {
        late http.Request capturedRequest;

        final service = DashboardService(
          client: MockClient((request) async {
            capturedRequest = request;
            return http.Response('[]', 200);
          }),
        );

        await service.fetchAgreements();

        expect(capturedRequest.method, 'GET');
        expect(
          capturedRequest.url,
          Uri.parse('${ApiConfig.baseUrl}/api/v1/dashboard/agreements'),
        );
        expect(capturedRequest.headers['accept'], 'application/json');
        expect(capturedRequest.body, isEmpty);
      });

      test('identifies the user by session only, with no user id or query', () async {
        late http.Request capturedRequest;

        final service = DashboardService(
          client: MockClient((request) async {
            capturedRequest = request;
            return http.Response('[]', 200);
          }),
        );

        await service.fetchAgreements();

        expect(capturedRequest.url.query, isEmpty);
        expect(capturedRequest.headers['authorization'], isNull);
      });

      test('returns the decoded agreements', () async {
        final service = _serviceReturning(
          () => http.Response(jsonEncode([_arrivalJson()]), 200),
        );

        final result = await service.fetchAgreements();

        expect(result, hasLength(1));
        expect(result.first['id'], 1);
        expect(result.first['listingId'], _listingId);
        expect(result.first['origin'], 'Steinbach');
        expect(result.first['status'], 'OPEN');
        expect(result.first['createdByCurrentUser'], isTrue);
        expect(result.first['daysOfWeek'], ['MONDAY', 'WEDNESDAY']);
        expect(result.first['drivers'], isA<List<dynamic>>());
        expect(result.first['passengers'], isA<List<dynamic>>());
      });

      test('keeps null fields as null for a one-way arrival ride', () async {
        final service = _serviceReturning(
          () => http.Response(jsonEncode([_arrivalJson()]), 200),
        );

        final agreement = (await service.fetchAgreements()).single;

        expect(agreement['rideType'], 'ARRIVAL');
        expect(agreement['arrivalTime'], '08:30');
        expect(agreement['departureTime'], isNull);
        expect(agreement['roundTripId'], isNull);
      });

      test('returns both legs of a round trip with their own listing ids', () async {
        final service = _serviceReturning(
          () => http.Response(jsonEncode(_roundTripJson()), 200),
        );

        final result = await service.fetchAgreements();

        expect(result, hasLength(2));
        expect(result.map((leg) => leg['rideType']), ['ARRIVAL', 'DEPARTURE']);
        expect(result.map((leg) => leg['listingId']), [_listingId, _otherLegId]);
        // One agreement: the legs share an agreement id and a round trip id.
        expect(result.map((leg) => leg['id']).toSet(), {1});
        expect(result.map((leg) => leg['roundTripId']).toSet(), {_roundTripId});
        expect(result.last['arrivalTime'], isNull);
        expect(result.last['departureTime'], '16:15');
      });

      test('returns an empty list when the user has no agreements', () async {
        final service = _serviceReturning(() => http.Response('[]', 200));

        expect(await service.fetchAgreements(), isEmpty);
      });

      test('returns every agreement in the response, in order', () async {
        final service = _serviceReturning(
          () => http.Response(
            jsonEncode([
              _arrivalJson()..['id'] = 1,
              _arrivalJson()..['id'] = 2,
              _arrivalJson()..['id'] = 3,
            ]),
            200,
          ),
        );

        final result = await service.fetchAgreements();

        expect(result.map((agreement) => agreement['id']), [1, 2, 3]);
      });

      test('throws an exception when the session is not authenticated', () async {
        final service = _serviceReturning(
          () => http.Response('{"message":"Unauthorized"}', 401),
        );

        await expectLater(
          service.fetchAgreements(),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('Loading ride agreements failed (401)'),
                contains('Unauthorized'),
              ),
            ),
          ),
        );
      });

      for (final status in [403, 429, 500]) {
        test('throws an exception containing the status code for HTTP $status', () async {
          final service = _serviceReturning(
            () => http.Response('Something went wrong', status),
          );

          await expectLater(
            service.fetchAgreements(),
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                allOf(
                  contains('Loading ride agreements failed ($status)'),
                  contains('Something went wrong'),
                ),
              ),
            ),
          );
        });
      }

      test('does not treat other success codes as success', () async {
        // The service only accepts 200; a 204 with no body is an error, not
        // an empty list. This documents that behaviour.
        final service = _serviceReturning(() => http.Response('', 204));

        await expectLater(
          service.fetchAgreements(),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('(204)'),
            ),
          ),
        );
      });

      test('throws when a 200 response is not a JSON array', () async {
        final service = _serviceReturning(
          () => http.Response('{"agreements": []}', 200),
        );

        await expectLater(service.fetchAgreements(), throwsA(isA<TypeError>()));
      });

      test('throws a FormatException when the body is not JSON', () async {
        final service = _serviceReturning(
          () => http.Response('<html>oops</html>', 200),
        );

        await expectLater(service.fetchAgreements(), throwsFormatException);
      });

      test('throws a FormatException when a 200 response has an empty body', () async {
        final service = _serviceReturning(() => http.Response('', 200));

        await expectLater(service.fetchAgreements(), throwsFormatException);
      });

      test('lets network failures propagate', () async {
        final service = DashboardService(
          client: MockClient((request) async => throw Exception('offline')),
        );

        await expectLater(
          service.fetchAgreements(),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('offline'),
            ),
          ),
        );
      });
    });
  });
}