package com.gobison.backend.features.rides.presentation;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record RideRequestDetailsResponse(
        UUID requestId,
        UUID roundTripId,
        RideType rideType,
        String city,
        String streetAddress,
        String arrivalTime,
        String departureTime,
        List<DayOfWeek> daysOfWeek,
        String description,
        String status) {

    public static RideRequestDetailsResponse from(RideRequest request) {
        var timeFormat = DateTimeFormatter.ofPattern("HH:mm");

        return new RideRequestDetailsResponse(
                request.getRequestId(),
                request.getRoundTripId(),
                request.getRideType(),
                request.getCity(),
                request.getStreetAddress(),
                request.getArrivalTime() == null
                        ? null : request.getArrivalTime().format(timeFormat),
                request.getDepartureTime() == null
                        ? null : request.getDepartureTime().format(timeFormat),
                request.getDaysOfWeek().stream().sorted().toList(),
                request.getDescription(),
                request.getStatus());
    }
}