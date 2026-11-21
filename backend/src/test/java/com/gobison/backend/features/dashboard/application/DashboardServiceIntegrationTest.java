package com.gobison.backend.features.dashboard.application;

import com.gobison.backend.features.dashboard.DashboardTestData;
import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.user.application.DeleteAccountService;
import com.gobison.backend.features.user.domain.repository.UserRepository;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;

import java.time.LocalTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Runs the real DashboardService against the real database.
 *
 * The @Sql script creates the ride tables if they are missing (CI builds only
 * the users table from JPA entities) and does nothing where they already exist.
 */
@SpringBootTest
@Sql("/ci_ride_agreements_schema.sql")
class DashboardServiceIntegrationTest {

    @Autowired
    private DashboardService service;

    @Autowired
    private DeleteAccountService deleteAccount;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private DashboardTestData data;

    @BeforeEach
    void setUp() {
        data = new DashboardTestData(jdbcTemplate, userRepository);
    }

    @AfterEach
    void cleanUp() {
        data.cleanUp();
    }

    @Test
    void shouldReturnEmptyListWhenUserHasNoListingsOrAgreements() {
        String email = data.createUser("Lonely", "User");

        assertTrue(service.getAgreementsFor(email).isEmpty());
    }

    @Test
    void deletingAccountCancelsBothLegsAndPreservesHistoryAndMembership() {
        String owner = data.createUser("Olive", "Owner");
        String passenger = data.createUser("Pat", "Passenger");
        UUID offerTrip = UUID.randomUUID();
        UUID requestTrip = UUID.randomUUID();
        var arrival = LocalTime.of(8, 30);
        var departure = LocalTime.of(16, 30);
        UUID offer = data.insertOffer(owner, "Steinbach", "ARRIVAL", arrival, null, "OPEN", offerTrip);
        data.insertOffer(owner, "Steinbach", "DEPARTURE", null, departure, "OPEN", offerTrip);
        data.insertRequest(owner, "Steinbach", "ARRIVAL", arrival, null, "OPEN", requestTrip);
        data.insertRequest(owner, "Steinbach", "DEPARTURE", null, departure, "OPEN", requestTrip);
        data.insertRequest(owner, "Steinbach", "ARRIVAL", arrival, null, "CLOSED", null);
        data.simpleOffer(passenger);
        long agreement = data.insertAgreementForOffer(offer);
        data.addMember(agreement, owner, "DRIVER");
        data.addMember(agreement, passenger, "PASSENGER");

        deleteAccount.delete(owner);

        assertTrue(userRepository.findByEmail(owner).orElseThrow().isDeleted());
        assertEquals(List.of("CANCELLED", "CANCELLED"), jdbcTemplate.queryForList(
                "SELECT status FROM ride_offers WHERE round_trip_id = ?", String.class, offerTrip));
        assertEquals(List.of("CANCELLED", "CANCELLED"), jdbcTemplate.queryForList(
                "SELECT status FROM ride_requests WHERE round_trip_id = ?", String.class, requestTrip));
        assertEquals("CLOSED", jdbcTemplate.queryForObject(
                "SELECT status FROM ride_requests WHERE user_email = ? AND round_trip_id IS NULL", String.class, owner));
        assertEquals("OPEN", jdbcTemplate.queryForObject(
                "SELECT status FROM ride_offers WHERE user_email = ?", String.class, passenger));
        assertTrue(service.getAgreementsFor(passenger).stream().anyMatch(item -> offer.equals(item.listingId())));
    }

    @Test
    void shouldReturnTheUsersOwnListing() {
        String email = data.createUser("Olive", "Owner");
        UUID offerId = data.simpleOffer(email);

        List<RideAgreementSummary> results = service.getAgreementsFor(email);

        assertEquals(1, results.size());
        assertEquals(offerId, results.get(0).listingId());
    }

    @Test
    void shouldFindUserWhenEmailHasDifferentCaseAndSurroundingSpaces() {
        String email = data.createUser("Olive", "Owner");
        UUID offerId = data.simpleOffer(email);

        List<RideAgreementSummary> results = service.getAgreementsFor("  " + email.toUpperCase() + "  ");

        assertEquals(1, results.size());
        assertEquals(offerId, results.get(0).listingId());
    }

    @Test
    void shouldLowercaseEmailWithRootLocaleEvenWhenDefaultLocaleIsTurkish() {
        String email = data.createUser("Olive", "Owner");
        UUID offerId = data.simpleOffer(email);

        Locale original = Locale.getDefault();
        try {
            // In a Turkish locale "I".toLowerCase() gives a dotless i, which would
            // turn MYUMANITOBA into an email that matches nobody.
            Locale.setDefault(Locale.forLanguageTag("tr-TR"));

            List<RideAgreementSummary> results = service.getAgreementsFor(email.toUpperCase(Locale.ROOT));

            assertEquals(1, results.size());
            assertEquals(offerId, results.get(0).listingId());
        } finally {
            Locale.setDefault(original);
        }
    }

    @Test
    void shouldReturnAgreementWithDriversAndPassengersForAJoinedMember() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        long agreementId = data.insertAgreementForOffer(data.simpleOffer(owner));
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        List<RideAgreementSummary> results = service.getAgreementsFor(joiner);

        assertEquals(1, results.size());
        assertAll(
                () -> assertEquals(Long.valueOf(agreementId), results.get(0).id()),
                () -> assertEquals(List.of(new AgreementMember(owner, "Olive", "Owner")), results.get(0).drivers()),
                () -> assertEquals(List.of(new AgreementMember(joiner, "Jo", "Joiner")), results.get(0).passengers())
        );
    }

    @Test
    void shouldNotReturnAnotherUsersListings() {
        String owner = data.createUser("Olive", "Owner");
        String stranger = data.createUser("Sam", "Stranger");
        data.simpleOffer(owner);

        assertTrue(service.getAgreementsFor(stranger).isEmpty());
    }

    @Test
    void shouldRejectNullEmail() {
        assertThrows(NullPointerException.class, () -> service.getAgreementsFor(null));
    }
}
