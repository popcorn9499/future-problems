import 'package:flutter/material.dart';
import 'package:gobison/core/models/ride_offer.dart';
import 'ride_offer_service.dart';

class RideOfferController extends ChangeNotifier {
  RideOfferController(this._rideOfferService);

  final RideOfferService _rideOfferService;

  bool isLoading = false;
  String? errorMessage;
  RideOffer? createdRideOffer;
  RideOffer? updatedRideOffer;

  Future<void> createRideOffer({
    required String userId,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required List<String> daysOfWeek,
    required int passengerNum,
    String? description,
  }) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      createdRideOffer = null;

      final trimmedCity = city.trim();
      final trimmedStreetAddress = streetAddress.trim();
      final trimmedDescription = description?.trim();

      final data = await _rideOfferService.createRideOffer(
        userId: userId,
        city: trimmedCity,
        streetAddress: trimmedStreetAddress,
        arrivalTime: arrivalTime,
        daysOfWeek: daysOfWeek,
        passengerNum: passengerNum,
        description: trimmedDescription?.isEmpty == true
          ? null
          : trimmedDescription,
      );

      createdRideOffer = RideOffer.fromJson(data);

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
        return 'Some ride offer details are invalid. Please check your entries.';
      case 401:
        return 'Unable to save your ride offer. Please try again.';
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
