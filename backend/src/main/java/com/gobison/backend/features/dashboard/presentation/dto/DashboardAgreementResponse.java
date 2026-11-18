package com.gobison.backend.features.dashboard.presentation.dto;

import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

public record DashboardAgreementResponse(
        Long id, //shared agreement ID
        String listingId, //identifies individual leg so its either an offer id or a request id
        String roundTripId, //shared by both legs, or null for one-way rides
        String rideType, //ARRIVAL or DEPARTURE
        String origin,
        String destination,
        String arrivalTime,
        String departureTime,
        List<DayOfWeek> daysOfWeek,
        String status,
        boolean createdByCurrentUser,
        List<Member> drivers,
        List<Member> passengers
) {
    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("HH:mm");

    public record Member(
            String id,
            String firstName,
            String lastName
    ) {
        static Member from(AgreementMember member) {
            return new Member(
                    member.email(),
                    member.firstName(),
                    member.lastName()
            );
        }
    }

    private static String formatTime(LocalTime time) {
        return time == null ? null : time.format(TIME_FORMAT);
    }

    public static DashboardAgreementResponse from(
        RideAgreementSummary agreement
    ) {
    return new DashboardAgreementResponse(
            agreement.id(),
            agreement.listingId().toString(),
            agreement.roundTripId() == null
                    ? null
                    : agreement.roundTripId().toString(),
            agreement.rideType(),
            agreement.origin(),
            agreement.destination(),
            formatTime(agreement.arrivalTime()),
            formatTime(agreement.departureTime()),
            agreement.daysOfWeek(),
            agreement.status(),
            agreement.createdByCurrentUser(),
            agreement.drivers().stream().map(Member::from).toList(),
            agreement.passengers().stream().map(Member::from).toList()
    );
  }
}