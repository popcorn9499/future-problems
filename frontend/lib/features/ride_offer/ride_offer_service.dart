import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';

enum RideOfferCancellationResult { cancelled, confirmationRequired }

class RideOfferService {
  RideOfferService({http.Client? client})
    : _client = client ?? createAuthClient();

  final http.Client _client;

  Uri _offerUri(String id) => Uri.parse(
    '${ApiConfig.baseUrl}/api/v1/rides/offers/${Uri.encodeComponent(id)}',
  );

  Future<Map<String, dynamic>> getRideOfferDetails(String offerId) async {
    final response = await _client.get(_offerUri(offerId), headers: {'Accept': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Loading ride offer failed (${response.statusCode}): ${response.body}');
  }

  Future<void> updateRideOffer({
    required String offerId,
    required String city,
    required String streetAddress,
    required List<String> daysOfWeek,
    required int passengerNum,
    required bool askingForDrivers,
    String? arrivalTime,
    String? departureTime,
    String? description,
  }) async {
    final response = await _client.patch(
      _offerUri(offerId),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'city': city,
        'streetAddress': streetAddress,
        'daysOfWeek': daysOfWeek.map((day) => day.toUpperCase()).toList(),
        'passengerNum': passengerNum,
        'askingForDrivers': askingForDrivers,
        'arrivalTime': arrivalTime,
        'departureTime': departureTime,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Updating ride offer failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<RideOfferCancellationResult> cancelRideOffer(String offerId, {bool confirmParticipants = false}) async {
    final uri = _offerUri(offerId);
    final response = await _client.delete(
      confirmParticipants ? uri.replace(queryParameters: {'confirmParticipants': 'true'}) : uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 204) return RideOfferCancellationResult.cancelled;
    final failure = Exception('Cancelling ride offer failed (${response.statusCode}): ${response.body}');
    if (response.statusCode == 409 && response.body.isNotEmpty) {
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['code'] == 'CONFIRMATION_REQUIRED') {
          return RideOfferCancellationResult.confirmationRequired;
        }
      } on FormatException {
        throw failure;
      }
    }
    throw failure;
  }

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
