package com.gobison.backend.features.dashboard;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;

import org.springframework.jdbc.core.JdbcTemplate;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * used by all dashboard integration tests
 * seeds users, listings and agreements for integration tests
 * and removes everything it created in cleanUp().
 *
 * create one per test in @BeforeEach and call cleanUp() in @AfterEach.
 * if ride_offers / ride_requests have other NOT NULL columns, add them to the
 * INSERTs below.
 */
public class DashboardTestData {

    private final JdbcTemplate jdbcTemplate;
    private final UserRepository userRepository;

    private final List<String> emails = new ArrayList<>();
    private final List<UUID> offerIds = new ArrayList<>();
    private final List<UUID> requestIds = new ArrayList<>();
    private final List<Long> agreementIds = new ArrayList<>();

    public DashboardTestData(JdbcTemplate jdbcTemplate, UserRepository userRepository) {
        this.jdbcTemplate = jdbcTemplate;
        this.userRepository = userRepository;
    }

    public String createUser(String firstName, String lastName) {
        String email = "test_" + UUID.randomUUID().toString().replace("-", "") + "@myumanitoba.ca";
        emails.add(email);
        userRepository.save(new User(email, "test-hash-not-a-real-password", firstName, lastName, false));
        return email;
    }

    public UUID insertOffer(
            String ownerEmail,
            String city,
            String rideType,
            LocalTime arrivalTime,
            LocalTime departureTime,
            String status,
            UUID roundTripId,
            DayOfWeek... days
    ) {
        UUID id = UUID.randomUUID();
        offerIds.add(id);
        jdbcTemplate.update(
                """
                INSERT INTO ride_offers (
                    offer_id, user_email, city, street_address, arrival_time, departure_time,
                    description, status, passenger_num, asking_for_drivers, ride_type, round_trip_id
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                id, ownerEmail, city, "1 Test Street", arrivalTime, departureTime,
                "test listing", status, 3, false, rideType, roundTripId
        );
        for (DayOfWeek day : days) {
            jdbcTemplate.update(
                    "INSERT INTO ride_offer_days (offer_id, day_of_week) VALUES (?, ?)",
                    id, day.name()
            );
        }
        return id;
    }

    public UUID insertRequest(
            String ownerEmail,
            String city,
            String rideType,
            LocalTime arrivalTime,
            LocalTime departureTime,
            String status,
            UUID roundTripId,
            DayOfWeek... days
    ) {
        UUID id = UUID.randomUUID();
        requestIds.add(id);
        jdbcTemplate.update(
                """
                INSERT INTO ride_requests (
                    request_id, user_email, city, street_address, arrival_time, departure_time,
                    description, status, ride_type, round_trip_id
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                id, ownerEmail, city, "1 Test Street", arrivalTime, departureTime,
                "test listing", status, rideType, roundTripId
        );
        for (DayOfWeek day : days) {
            jdbcTemplate.update(
                    "INSERT INTO ride_request_days (request_id, day_of_week) VALUES (?, ?)",
                    id, day.name()
            );
        }
        return id;
    }

    /** One-way open arrival offer, 08:30 from Steinbach, Monday and Wednesday. */
    public UUID simpleOffer(String ownerEmail) {
        return insertOffer(ownerEmail, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "OPEN", null, DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY);
    }

    public long insertAgreementForOffer(UUID offerId) {
        Long id = jdbcTemplate.queryForObject(
                "INSERT INTO ride_agreements (offer_id) VALUES (?) RETURNING agreement_id",
                Long.class, offerId);
        agreementIds.add(id);
        return id;
    }

    public long insertAgreementForRequest(UUID requestId) {
        Long id = jdbcTemplate.queryForObject(
                "INSERT INTO ride_agreements (request_id) VALUES (?) RETURNING agreement_id",
                Long.class, requestId);
        agreementIds.add(id);
        return id;
    }

    public void addMember(long agreementId, String email, String role) {
        jdbcTemplate.update(
                "INSERT INTO ride_agreement_members (agreement_id, user_email, role) VALUES (?, ?, ?)",
                agreementId, email, role
        );
    }

    /** Deletes everything this instance created, children before parents. */
    public void cleanUp() {
        for (Long agreementId : agreementIds) {
            jdbcTemplate.update("DELETE FROM ride_agreement_members WHERE agreement_id = ?", agreementId);
            jdbcTemplate.update("DELETE FROM ride_agreements WHERE agreement_id = ?", agreementId);
        }
        for (UUID offerId : offerIds) {
            jdbcTemplate.update("DELETE FROM ride_offer_days WHERE offer_id = ?", offerId);
            jdbcTemplate.update("DELETE FROM ride_offers WHERE offer_id = ?", offerId);
        }
        for (UUID requestId : requestIds) {
            jdbcTemplate.update("DELETE FROM ride_request_days WHERE request_id = ?", requestId);
            jdbcTemplate.update("DELETE FROM ride_requests WHERE request_id = ?", requestId);
        }
        for (String email : emails) {
            userRepository.deleteByEmail(email);
        }
        agreementIds.clear();
        offerIds.clear();
        requestIds.clear();
        emails.clear();
    }
}