package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

public record RideOfferResponse(
        RideType rideType,
        String departureTime,
        UUID roundTripId,
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
                rideOffer.getRideType(),
                rideOffer.getDepartureTime() == null ? null
                        : rideOffer.getDepartureTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideOffer.getRoundTripId(),
                rideOffer.getOfferId(),
                rideOffer.getUserId(),
                rideOffer.getCity(),
                rideOffer.getStreetAddress(),
                rideOffer.getArrivalTime() == null ? null
                        : rideOffer.getArrivalTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideOffer.getDaysOfWeek().stream().sorted().toList(),
                rideOffer.getDescription(),
                rideOffer.getStatus(),
                rideOffer.getPassengerNum(),
                rideOffer.isAskingForDrivers());
    }
}
