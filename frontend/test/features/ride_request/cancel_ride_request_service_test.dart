import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/network/api_config.dart';
import 'package:gobison/features/ride_request/ride_request_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const requestId = '48d7ab78-af97-42b4-b1fa-112372796faa';
  final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides/requests/$requestId');

  test('asks for confirmation before cancelling a request with participants', () async {
    final calls = <Uri>[];
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      calls.add(request.url);

      if (request.url.queryParameters['confirmParticipants'] == 'true') {
        return http.Response('', 204);
      }

      return http.Response('{"code":"CONFIRMATION_REQUIRED"}', 409);
    });
    final service = RideRequestService(client: client);

    final first = await service.cancelRideRequest(requestId);

    expect(first, RideRequestCancellationResult.confirmationRequired);
    expect(calls, [url]);

    final confirmed = await service.cancelRideRequest(
      requestId,
      confirmParticipants: true,
    );

    expect(confirmed, RideRequestCancellationResult.cancelled);
    expect(calls, [
      url,
      url.replace(queryParameters: {'confirmParticipants': 'true'}),
    ]);
  });

  test('reports other conflicts as errors', () async {
    final client = MockClient((_) async {
      return http.Response('{"status":409,"error":"Conflict"}', 409);
    });
    final service = RideRequestService(client: client);

    await expectLater(
      service.cancelRideRequest(requestId),
      throwsA(isA<Exception>()),
    );
  });
}