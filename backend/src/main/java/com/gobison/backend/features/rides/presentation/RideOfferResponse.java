package com.gobison.backend.features.rides.presentation;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record RideOfferResponse(
        RideType rideType,
        String departureTime,
        UUID roundTripId,
        UUID offerId,
        UUID arrivalId,
        UUID departureId,
        String userId,
        String city,
        String streetAddress,
        String arrivalTime,
        List<DayOfWeek> daysOfWeek,
        String description,
        String status,
        int passengerNum,
        boolean askingForDrivers) {

    public static RideOfferResponse from(List<RideOffer> savedLegs) {
        var arrival = savedLegs.stream()
                .filter(leg -> leg.getRideType() == RideType.ARRIVAL)
                .findFirst().orElse(null);
        var departure = savedLegs.stream()
                .filter(leg -> leg.getRideType() == RideType.DEPARTURE)
                .findFirst().orElse(null);
        var rideOffer = savedLegs.getFirst();
        boolean roundTrip = arrival != null && departure != null;

        return new RideOfferResponse(
                roundTrip ? RideType.ROUND_TRIP : rideOffer.getRideType(),
                departure == null ? null
                        : departure.getDepartureTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideOffer.getRoundTripId(),
                roundTrip ? null : rideOffer.getOfferId(),
                arrival == null ? null : arrival.getOfferId(),
                departure == null ? null : departure.getOfferId(),
                rideOffer.getUserId(),
                rideOffer.getCity(),
                rideOffer.getStreetAddress(),
                arrival == null ? null
                        : arrival.getArrivalTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideOffer.getDaysOfWeek().stream().sorted().toList(),
                rideOffer.getDescription(),
                rideOffer.getStatus(),
                rideOffer.getPassengerNum(),
                rideOffer.isAskingForDrivers());
    }
}
