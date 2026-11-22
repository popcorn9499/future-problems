import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:gobison/core/models/ride_offer.dart';
import 'ride_offer_service.dart';

class RideOfferController extends ChangeNotifier {
  RideOfferController(this._rideOfferService);

  final RideOfferService _rideOfferService;

  bool isLoading = false;
  String? errorMessage;
  bool invalidAddress = false;
  RideOffer? createdRideOffer;
  RideOffer? updatedRideOffer;

  Future<void> createRideOffer({
    required String userId,
    required String rideType,
    required String city,
    required String streetAddress,
    LatLng? location,
    required String? arrivalTime,
    required String? departureTime,
    required List<String> daysOfWeek,
    required int passengerNum,
    String? description,
    required bool askingForDrivers,
  }) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;
    invalidAddress = false;
    notifyListeners();

    try {
      createdRideOffer = null;

      final trimmedCity = city.trim();
      final trimmedStreetAddress = streetAddress.trim();
      final trimmedDescription = description?.trim();

      final data = await _rideOfferService.createRideOffer(
        userId: userId,
        rideType: rideType,
        city: trimmedCity,
        streetAddress: trimmedStreetAddress,
        location: location,
        arrivalTime: arrivalTime,
        departureTime: departureTime,
        daysOfWeek: daysOfWeek,
        passengerNum: passengerNum,
        description: trimmedDescription?.isEmpty == true
          ? null
          : trimmedDescription,
        askingForDrivers: askingForDrivers,
      );

      createdRideOffer = RideOffer.fromJson(data);

    } catch (e) {
      final code = extractErrorCode(e);
      invalidAddress = code == 422;
      errorMessage = _handleError(code);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _handleError(int code) {
    switch (code) {
      case 400:
        return 'Some ride offer details are invalid. Please check your entries.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'Verify your email before posting a ride.';
      case 422:
        return 'We couldn’t locate that address in Canada. Check the street address and city and try again.';
      case 503:
        return 'Address lookup is temporarily unavailable. Please try again.';
      case 500:
        return 'Something went wrong. Please try again later.';
      default:
        return 'Unable to save your ride offer. Please try again.';
    }
  }
}

int extractErrorCode(Object e) {
  final match = RegExp(r'\((\d{3})\)').firstMatch(e.toString());
  return match == null ? -1 : int.parse(match.group(1)!);
}
