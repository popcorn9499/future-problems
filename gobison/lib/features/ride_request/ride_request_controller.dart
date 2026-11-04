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
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required List<String> daysOfWeek,
    String? description,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      createdRideRequest = null;

      final data = await _rideRequestService.createRideRequest(
        userId: userId,
        city: city,
        streetAddress: streetAddress,
        arrivalTime: arrivalTime,
        daysOfWeek: daysOfWeek,
        description: description,
      );

      createdRideRequest = RideRequest.fromJson(data);

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRideRequest({
    required RideRequest currentRideRequest,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required List<String> daysOfWeek,
    required String description,
  }) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    updatedRideRequest = null;
    notifyListeners();

    try {
      final trimmedCity = city.trim();
      final trimmedStreetAddress = streetAddress.trim();
      final trimmedDescription = description.trim();

      final editedRideRequest = RideRequest(
        userId: currentRideRequest.userId,
        city: trimmedCity,
        streetAddress: trimmedStreetAddress,
        arrivalTime: arrivalTime,
        daysOfWeek: daysOfWeek,
        description: trimmedDescription.isEmpty ? null : trimmedDescription,
      );

      final changes = <String, dynamic>{};

      if (editedRideRequest.city != currentRideRequest.city) {
        changes['city'] = editedRideRequest.city;
      }

      if (editedRideRequest.streetAddress != currentRideRequest.streetAddress) {
        changes['streetAddress'] = editedRideRequest.streetAddress;
      }

      if (editedRideRequest.arrivalTime != currentRideRequest.arrivalTime) {
        changes['arrivalTime'] = editedRideRequest.arrivalTime;
      }

      if (editedRideRequest.daysOfWeek != currentRideRequest.daysOfWeek) {
        changes['daysOfWeek'] = editedRideRequest.daysOfWeek;
      }

      if (editedRideRequest.description != currentRideRequest.description) {
        changes['description'] = editedRideRequest.description;
      }

      if (changes.isEmpty) {
        updatedRideRequest = currentRideRequest;
        return;
      }

      updatedRideRequest = await _rideRequestService.updateRideRequest(changes: changes);
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
        return 'Some ride reuqest details are invalid. Please check your entries.';
      case 401:
        return 'Unable to save your ride request. Please try again.';
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
