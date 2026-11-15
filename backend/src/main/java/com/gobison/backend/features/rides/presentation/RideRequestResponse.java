package com.gobison.backend.features.rides.presentation;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record RideRequestResponse(
        RideType rideType,
        String departureTime,
        UUID roundTripId,
        UUID requestId,
        UUID arrivalId,
        UUID departureId,
        String userId,
        String city,
        String streetAddress,
        String arrivalTime,
        List<DayOfWeek> daysOfWeek,
        String description,
        String status) {

    public static RideRequestResponse from(List<RideRequest> savedLegs) {
        var arrival = savedLegs.stream()
                .filter(leg -> leg.getRideType() == RideType.ARRIVAL)
                .findFirst().orElse(null);
        var departure = savedLegs.stream()
                .filter(leg -> leg.getRideType() == RideType.DEPARTURE)
                .findFirst().orElse(null);
        var rideRequest = savedLegs.getFirst();
        boolean roundTrip = arrival != null && departure != null;

        return new RideRequestResponse(
                roundTrip ? RideType.ROUND_TRIP : rideRequest.getRideType(),
                departure == null ? null
                        : departure.getDepartureTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideRequest.getRoundTripId(),
                roundTrip ? null : rideRequest.getRequestId(),
                arrival == null ? null : arrival.getRequestId(),
                departure == null ? null : departure.getRequestId(),
                rideRequest.getUserId(),
                rideRequest.getCity(),
                rideRequest.getStreetAddress(),
                arrival == null ? null
                        : arrival.getArrivalTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideRequest.getDaysOfWeek().stream().sorted().toList(),
                rideRequest.getDescription(),
                rideRequest.getStatus());
    }
}
