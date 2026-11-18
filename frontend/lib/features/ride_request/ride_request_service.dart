import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';

enum RideRequestCancellationResult { cancelled, confirmationRequired }

class RideRequestService {
  RideRequestService({http.Client? client}) : _client = client ?? createAuthClient();

  final http.Client _client;

  Future<Map<String, dynamic>> getRideRequestDetails(String requestId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/rides/requests/${Uri.encodeComponent(requestId)}',
    );
    final response = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Loading ride request failed (${response.statusCode}): ${response.body}');
  }

  Future<void> updateRideRequest({
    required String requestId,
    required bool roundTrip,
    required String city,
    required String streetAddress,
    required List<String> daysOfWeek,
    String? arrivalTime,
    String? departureTime,
    String? description,
  }) async {
    final suffix = roundTrip ? '/round-trip' : '';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/rides/requests/${Uri.encodeComponent(requestId)}$suffix',
    );
    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'city': city,
        'streetAddress': streetAddress,
        'daysOfWeek': daysOfWeek.map((day) => day.toUpperCase()).toList(),
        'arrivalTime': arrivalTime,
        'departureTime': departureTime,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Updating ride request failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createRideRequest({
    required String userId,
    required String rideType,
    required String city,
    required String streetAddress,
    required String? arrivalTime,
    required String? departureTime,
    required List<String> daysOfWeek,
    String? description,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides/requests');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'rideType': rideType,
        'city': city,
        'streetAddress': streetAddress,
        'arrivalTime': arrivalTime,
        'departureTime': departureTime,
        'daysOfWeek': daysOfWeek.map((day) => day.toUpperCase()).toList(),
        'description': description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Ride request creation failed (${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<RideRequestCancellationResult> cancelRideRequest(
    String requestId, {
    bool confirmParticipants = false,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/rides/requests/${Uri.encodeComponent(requestId)}',
    ).replace(
      queryParameters: confirmParticipants ? {'confirmParticipants': 'true'} : null,
    );

    final response = await _client.delete(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 204) {
      return RideRequestCancellationResult.cancelled;
    }

    final error = Exception(
      'Ride request cancellation failed (${response.statusCode}): '
      '${response.body}',
    );

    if (response.statusCode == 409) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['code'] == 'CONFIRMATION_REQUIRED') {
          return RideRequestCancellationResult.confirmationRequired;
        }
      } on FormatException {
        throw error;
      }
    }

    throw error;
  }
}