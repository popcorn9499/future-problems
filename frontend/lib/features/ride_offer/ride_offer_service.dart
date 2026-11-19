import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';

class RideOfferService {
  RideOfferService({http.Client? client})
    : _client = client ?? createAuthClient();

  final http.Client _client;

  Future<Map<String, dynamic>> createRideOffer({
    required String userId,
    required String rideType,
    required String city,
    required String streetAddress,
    required String? arrivalTime,
    required String? departureTime,
    required int passengerNum,
    required List<String> daysOfWeek,
    String? description,
    required bool askingForDrivers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides/offers');
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
        'passengerNum': passengerNum,
        'description': description,
        'askingForDrivers': askingForDrivers,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Ride offer creation failed (${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<Map<String, dynamic>> retrieveRideOffers({
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides/offers')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Retrieving ride offers failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}
