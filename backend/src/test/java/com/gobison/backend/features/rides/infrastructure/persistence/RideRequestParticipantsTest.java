package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.dashboard.DashboardTestData;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@Transactional
@Sql("/ci_ride_agreements_schema.sql")
class RideRequestParticipantsTest {

    @Autowired
    private RideRequestRepository requests;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private UserRepository users;

    private DashboardTestData data;

    @BeforeEach
    void setUp() {
        data = new DashboardTestData(jdbc, users);
    }

    @Test
    void ownerAloneDoesNotCountAsAnotherParticipant() {
        String owner = data.createUser("Ride", "Owner");
        UUID requestId = data.insertRequest(
                owner, "Winnipeg", "ARRIVAL", LocalTime.of(8, 0), null,
                "OPEN", null, DayOfWeek.MONDAY);

        assertFalse(requests.hasOtherParticipants(requestId));

        long agreementId = data.insertAgreementForRequest(requestId);
        data.addMember(agreementId, owner, "PASSENGER");

        assertFalse(requests.hasOtherParticipants(requestId));
    }

    @Test
    void memberOnReturnLegIsDetectedFromEitherLeg() {
        String owner = data.createUser("Ride", "Owner");
        String driver = data.createUser("Other", "Driver");
        UUID roundTripId = UUID.randomUUID();

        UUID arrivalId = data.insertRequest(
                owner, "Winnipeg", "ARRIVAL", LocalTime.of(8, 0), null,
                "OPEN", roundTripId, DayOfWeek.MONDAY);
        UUID departureId = data.insertRequest(
                owner, "Winnipeg", "DEPARTURE", null, LocalTime.of(17, 0),
                "OPEN", roundTripId, DayOfWeek.MONDAY);

        long agreementId = data.insertAgreementForRequest(departureId);
        data.addMember(agreementId, driver, "DRIVER");

        assertTrue(requests.hasOtherParticipants(arrivalId));
        assertTrue(requests.hasOtherParticipants(departureId));
    }
}