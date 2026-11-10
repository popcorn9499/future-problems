import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';

class RideRequestService {
  RideRequestService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> createRideRequest({
    required String userId,
    required String city,
    required String streetAddress,
    required String arrivalTime,
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
        'userId': userId,
        'city': city,
        'streetAddress': streetAddress,
        'arrivalTime': arrivalTime,
        'daysOfWeek': daysOfWeek,
        'description': description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Ride request creation failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}
