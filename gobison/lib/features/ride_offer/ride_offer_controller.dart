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
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      createdRideOffer = null;

      final data = await _rideOfferService.createRideOffer(
        userId: userId,
        city: city,
        streetAddress: streetAddress,
        arrivalTime: arrivalTime,
        daysOfWeek: daysOfWeek,
        passengerNum: passengerNum,
        description: description,
      );

      createdRideOffer = RideOffer.fromJson(data);

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRideOffer({
    required RideOffer currentRideOffer,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required List<String> daysOfWeek,
    required int passengerNum,
    required String description,
  }) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    updatedRideOffer = null;
    notifyListeners();

    try {
      final trimmedCity = city.trim();
      final trimmedStreetAddress = streetAddress.trim();
      final trimmedDescription = description.trim();

      final editedRideOffer = RideOffer(
        userId: currentRideOffer.userId,
        city: trimmedCity,
        streetAddress: trimmedStreetAddress,
        arrivalTime: arrivalTime,
        daysOfWeek: daysOfWeek,
        passengerNum: passengerNum,
        description: trimmedDescription.isEmpty ? null : trimmedDescription,
      );

      final changes = <String, dynamic>{};

      if (editedRideOffer.city != currentRideOffer.city) {
        changes['city'] = editedRideOffer.city;
      }

      if (editedRideOffer.streetAddress != currentRideOffer.streetAddress) {
        changes['streetAddress'] = editedRideOffer.streetAddress;
      }

      if (editedRideOffer.arrivalTime != currentRideOffer.arrivalTime) {
        changes['arrivalTime'] = editedRideOffer.arrivalTime;
      }

      if (editedRideOffer.daysOfWeek != currentRideOffer.daysOfWeek) {
        changes['daysOfWeek'] = editedRideOffer.daysOfWeek;
      }

      if (editedRideOffer.passengerNum != currentRideOffer.passengerNum) {
        changes['passengerNum'] = editedRideOffer.passengerNum;
      }

      if (editedRideOffer.description != currentRideOffer.description) {
        changes['description'] = editedRideOffer.description;
      }

      if (changes.isEmpty) {
        updatedRideOffer = currentRideOffer;
        return;
      }

      updatedRideOffer = await _rideOfferService.updateRideOffer(changes: changes);
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
        return 'Unable to save your ride Offer. Please try again.';
      case 500:
        return 'Something went wrong. Please try again later.';
      default:
        return 'Unable to save your ride Offer. Please try again.';
    }
  }
}

int extractErrorCode(Object e) {
  final match = RegExp(r'\((\d{3})\)').firstMatch(e.toString());
  return match == null ? -1 : int.parse(match.group(1)!);
}
