package com.gobison.backend.features.dashboard.domain.model;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
 
/**
 * Read-only view of a recurring ride agreement, shaped for the dashboard.
 * Deliberately separate from whatever entities the ride request feature
 * ends up with, so their schema can change without breaking the dashboard.
 */
public record RideAgreementSummary(
        Long id,
        String origin,
        String destination,
        LocalTime departureTime,
        List<DayOfWeek> daysOfWeek,
        String status,
        List<AgreementMember> drivers,
        List<AgreementMember> passengers
) { //TODO: add a field to determine if the arrangement was created by current user or not
}