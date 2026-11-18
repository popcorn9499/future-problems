import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';

class RideRequestService {
  RideRequestService({http.Client? client})
    : _client = client ?? createAuthClient();

  final http.Client _client;

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

  Future<Map<String, dynamic>> retrieveRideRequests({
    String? city,
    String? daysOfWeek,
    String? rideType,
    String? departureTime,
    String? arrivalTime,
    String? status,
  }) async {
    // Build a map of query parameters, omitting null or empty values
    final queryParams = <String, String>{};

    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
      queryParams['daysOfWeek'] = daysOfWeek;
    }
    if (rideType != null && rideType.isNotEmpty) {
      queryParams['rideType'] = rideType;
    }
    if (departureTime != null && departureTime.isNotEmpty) {
      queryParams['departureTime'] = departureTime;
    }
    if (arrivalTime != null && arrivalTime.isNotEmpty) {
      queryParams['arrivalTime'] = arrivalTime;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    // Construct the URI and attach query parameters only if the map is not empty
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides/requests')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Retrieving ride requests failed (${response.statusCode}): ${response.body}',
    );
  }
}
