package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.domain.model.RideRequest;

import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

public record RideRequestResponse(
        UUID requestId,
        String userId,
        String city,
        String streetAddress,
        String arrivalTime,
        List<DayOfWeek> daysOfWeek,
        String description,
        String status) {

    public static RideRequestResponse from(RideRequest rideRequest) {
        return new RideRequestResponse(
                rideRequest.getRequestId(),
                rideRequest.getUserId(),
                rideRequest.getCity(),
                rideRequest.getStreetAddress(),
                rideRequest.getArrivalTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                rideRequest.getDaysOfWeek().stream().sorted().toList(),
                rideRequest.getDescription(),
                rideRequest.getStatus());
    }
}
