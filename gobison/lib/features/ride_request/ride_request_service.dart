import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';

class RideRequestService {
  RideRequestService({http.Client? client})
    : _client = client ?? createAuthClient();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> createRideRequest({
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
      final data = jsonDecode(response.body) as List;
      return data.map((leg) => Map<String, dynamic>.from(leg as Map)).toList();
    }

    throw Exception(
      'Ride request creation failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}
