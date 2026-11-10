import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';

class RideOfferService {
  RideOfferService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> createRideOffer({
    required String userId,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required int passengerNum,
    required List<String> daysOfWeek,
    String? description,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides/offers');
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
        'passengerNum': passengerNum,
        'description': description,
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
}
