package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.domain.model.RideOffer;

import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

public record RideOfferResponse(
        UUID offerId,
        String userId,
        String city,
        String streetAddress,
        String arrivalTime,
        List<DayOfWeek> daysOfWeek,
        String description,
        String status,
        int passengerNum,
        boolean askingForDrivers) {

    public static RideOfferResponse from(RideOffer rideOffer) {
        return new RideOfferResponse(
                rideOffer.getOfferId(),
                rideOffer.getUserId(),
                rideOffer.getCity(),
                rideOffer.getStreetAddress(),
                rideOffer.getArrivalTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideOffer.getDaysOfWeek().stream().sorted().toList(),
                rideOffer.getDescription(),
                rideOffer.getStatus(),
                rideOffer.getPassengerNum(),
                rideOffer.isAskingForDrivers());
    }
}
