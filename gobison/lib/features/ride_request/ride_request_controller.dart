import 'package:flutter/material.dart';
import 'package:gobison/core/models/ride_request.dart';

import 'ride_request_service.dart';

class RideRequestController extends ChangeNotifier {
  RideRequestController(this._rideRequestService);

  final RideRequestService _rideRequestService;

  bool isLoading = false;
  String? errorMessage;
  RideRequest? createdRideRequest;
  RideRequest? updatedRideRequest;

  Future<void> createRideRequest({
    required String userId,
    required String rideType,
    required String city,
    required String streetAddress,
    required String? arrivalTime,
    required String? departureTime,
    required List<String> daysOfWeek,
    String? description,
  }) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      createdRideRequest = null;

      final trimmedCity = city.trim();
      final trimmedStreetAddress = streetAddress.trim();
      final trimmedDescription = description?.trim();

      final data = await _rideRequestService.createRideRequest(
        userId: userId,
        rideType: rideType,
        city: trimmedCity,
        streetAddress: trimmedStreetAddress,
        arrivalTime: arrivalTime,
        departureTime: departureTime,
        daysOfWeek: daysOfWeek,
        description: trimmedDescription?.isEmpty == true
            ? null
            : trimmedDescription,
      );

      createdRideRequest = RideRequest.fromJson(data);
    } catch (e) {
      errorMessage = _handleError(extractErrorCode(e));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _handleError(int code) {
    switch (code) {
      case 400:
        return 'Some ride request details are invalid. Please check your entries.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'Verify your email before posting a ride.';
      case 500:
        return 'Something went wrong. Please try again later.';
      default:
        return 'Unable to save your ride request. Please try again.';
    }
  }
}

int extractErrorCode(Object e) {
  final match = RegExp(r'\((\d{3})\)').firstMatch(e.toString());
  return match == null ? -1 : int.parse(match.group(1)!);
}
