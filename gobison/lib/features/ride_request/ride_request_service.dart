import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import 'package:gobison/core/models/ride_request.dart';

class RideRequestService {
  RideRequestService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> createRideRequest({
    required String userId,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required List<String> daysOfWeek,
    int? passengerNum,
    String? description,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/riderequest/create');
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

  Future<RideRequest> updateRideRequest({
    required Map<String, dynamic> changes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/riderequest/update');

    final response = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(changes),
    );

    if (response.statusCode == 200) {
      return RideRequest.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Ride request update failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}
