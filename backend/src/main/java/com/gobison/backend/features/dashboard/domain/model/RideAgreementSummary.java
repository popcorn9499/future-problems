package com.gobison.backend.features.dashboard.domain.model;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

public record RideAgreementSummary(
        Long id,                       // Agreement ID
        UUID listingId,              // Individual offer/request ID
        UUID roundTripId,            // Null for one-way rides
        String rideType,               // ARRIVAL or DEPARTURE
        String origin,
        String destination,
        LocalTime arrivalTime,
        LocalTime departureTime,
        List<DayOfWeek> daysOfWeek,
        String status,
        boolean createdByCurrentUser,
        List<AgreementMember> drivers,
        List<AgreementMember> passengers
) {}