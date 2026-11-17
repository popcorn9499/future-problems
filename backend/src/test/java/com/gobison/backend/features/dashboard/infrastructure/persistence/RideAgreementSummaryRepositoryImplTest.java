package com.gobison.backend.features.dashboard.infrastructure.persistence;

import com.gobison.backend.features.dashboard.DashboardTestData;
import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.dashboard.domain.repository.RideAgreementSummaryRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration test against the real database, like UserRepositoryImplTest.
 * DashboardTestData seeds the rows and deletes them again after each test.
 *
 * The @Sql script creates the ride tables if they are missing (CI builds only
 * the users table from JPA entities) and does nothing where they already exist.
 */
@SpringBootTest
@Sql("/ci_ride_agreements_schema.sql")
class RideAgreementSummaryRepositoryImplTest {

    private static final String CAMPUS = "University of Manitoba";

    @Autowired
    private RideAgreementSummaryRepository repository;

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

    private static RideAgreementSummary legOfType(List<RideAgreementSummary> results, String rideType) {
        return results.stream()
                .filter(r -> rideType.equals(r.rideType()))
                .findFirst()
                .orElseThrow();
    }

    @Test
    void shouldReturnEmptyListWhenUserHasNoListingsOrAgreements() {
        String lonely = data.createUser("Lonely", "User");

        assertTrue(repository.findByMemberEmail(lonely).isEmpty());
    }

    @Test
    void shouldReturnOwnUnjoinedOfferWithOwnerAsOnlyDriver() {
        String owner = data.createUser("Olive", "Owner");
        UUID offerId = data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "OPEN", null, DayOfWeek.FRIDAY, DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY);

        List<RideAgreementSummary> results = repository.findByMemberEmail(owner);

        assertEquals(1, results.size());
        RideAgreementSummary ticket = results.get(0);
        assertAll(
                () -> assertNull(ticket.id()),
                () -> assertEquals(offerId, ticket.listingId()),
                () -> assertNull(ticket.roundTripId()),
                () -> assertEquals("ARRIVAL", ticket.rideType()),
                () -> assertEquals("Steinbach", ticket.origin()),
                () -> assertEquals(CAMPUS, ticket.destination()),
                () -> assertEquals(LocalTime.of(8, 30), ticket.arrivalTime()),
                () -> assertNull(ticket.departureTime()),
                // inserted as Friday, Monday, Wednesday; must come back Monday to Friday
                () -> assertEquals(
                        List.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
                        ticket.daysOfWeek()),
                () -> assertEquals("OPEN", ticket.status()),
                () -> assertTrue(ticket.createdByCurrentUser()),
                () -> assertEquals(List.of(new AgreementMember(owner, "Olive", "Owner")), ticket.drivers()),
                () -> assertTrue(ticket.passengers().isEmpty())
        );
    }

    @Test
    void shouldReturnOwnUnjoinedRequestWithOwnerAsOnlyPassenger() {
        String owner = data.createUser("Rhea", "Rider");
        UUID requestId = data.insertRequest(owner, "Winnipeg", "ARRIVAL", LocalTime.of(9, 0), null,
                "OPEN", null, DayOfWeek.TUESDAY);

        List<RideAgreementSummary> results = repository.findByMemberEmail(owner);

        assertEquals(1, results.size());
        RideAgreementSummary ticket = results.get(0);
        assertAll(
                () -> assertNull(ticket.id()),
                () -> assertEquals(requestId, ticket.listingId()),
                () -> assertEquals("Winnipeg", ticket.origin()),
                () -> assertEquals(CAMPUS, ticket.destination()),
                () -> assertEquals(List.of(DayOfWeek.TUESDAY), ticket.daysOfWeek()),
                () -> assertTrue(ticket.createdByCurrentUser()),
                () -> assertTrue(ticket.drivers().isEmpty()),
                () -> assertEquals(List.of(new AgreementMember(owner, "Rhea", "Rider")), ticket.passengers())
        );
    }

    @Test
    void shouldReturnAgreementToAJoinedMemberWithDriversAndPassengers() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        UUID offerId = data.simpleOffer(owner);
        long agreementId = data.insertAgreementForOffer(offerId);
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        List<RideAgreementSummary> results = repository.findByMemberEmail(joiner);

        assertEquals(1, results.size());
        RideAgreementSummary ticket = results.get(0);
        assertAll(
                () -> assertEquals(Long.valueOf(agreementId), ticket.id()),
                () -> assertEquals(offerId, ticket.listingId()),
                () -> assertFalse(ticket.createdByCurrentUser()),
                () -> assertEquals(List.of(new AgreementMember(owner, "Olive", "Owner")), ticket.drivers()),
                () -> assertEquals(List.of(new AgreementMember(joiner, "Jo", "Joiner")), ticket.passengers())
        );
    }

    @Test
    void shouldReturnRequestAgreementWithTheJoiningDriver() {
        String requester = data.createUser("Rhea", "Rider");
        String driver = data.createUser("Dana", "Driver");
        UUID requestId = data.insertRequest(requester, "Winnipeg", "ARRIVAL", LocalTime.of(9, 0), null,
                "FULL", null, DayOfWeek.TUESDAY);
        long agreementId = data.insertAgreementForRequest(requestId);
        data.addMember(agreementId, requester, "PASSENGER");
        data.addMember(agreementId, driver, "DRIVER");

        List<RideAgreementSummary> results = repository.findByMemberEmail(driver);

        assertEquals(1, results.size());
        RideAgreementSummary ticket = results.get(0);
        assertAll(
                () -> assertEquals(Long.valueOf(agreementId), ticket.id()),
                () -> assertEquals(requestId, ticket.listingId()),
                () -> assertFalse(ticket.createdByCurrentUser()),
                () -> assertEquals(List.of(new AgreementMember(driver, "Dana", "Driver")), ticket.drivers()),
                () -> assertEquals(List.of(new AgreementMember(requester, "Rhea", "Rider")), ticket.passengers())
        );
    }

    @Test
    void shouldReturnAgreementOnceForTheCreatorWhoIsAlsoAMember() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        long agreementId = data.insertAgreementForOffer(data.simpleOffer(owner));
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        List<RideAgreementSummary> results = repository.findByMemberEmail(owner);

        // One agreement ticket: not duplicated by the creator being a member, and
        // not repeated as an "unjoined" listing now that an agreement exists.
        assertEquals(1, results.size());
        assertTrue(results.get(0).createdByCurrentUser());
        assertEquals(Long.valueOf(agreementId), results.get(0).id());
    }

    @Test
    void shouldReturnBothLegsOfARoundTripUnderOneAgreement() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        UUID roundTripId = UUID.randomUUID();
        UUID arrivalId = data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "OPEN", roundTripId, DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY);
        UUID departureId = data.insertOffer(owner, "Steinbach", "DEPARTURE", null, LocalTime.of(16, 15),
                "OPEN", roundTripId, DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY);
        long agreementId = data.insertAgreementForOffer(arrivalId);
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        List<RideAgreementSummary> results = repository.findByMemberEmail(joiner);

        assertEquals(2, results.size());
        RideAgreementSummary arrival = legOfType(results, "ARRIVAL");
        RideAgreementSummary departure = legOfType(results, "DEPARTURE");
        assertAll(
                () -> assertEquals(Long.valueOf(agreementId), arrival.id()),
                () -> assertEquals(Long.valueOf(agreementId), departure.id()),
                () -> assertEquals(arrivalId, arrival.listingId()),
                () -> assertEquals(departureId, departure.listingId()),
                () -> assertEquals(roundTripId, arrival.roundTripId()),
                () -> assertEquals(roundTripId, departure.roundTripId()),
                () -> assertEquals("Steinbach", arrival.origin()),
                () -> assertEquals(CAMPUS, arrival.destination()),
                () -> assertEquals(CAMPUS, departure.origin()),
                () -> assertEquals("Steinbach", departure.destination()),
                () -> assertEquals(LocalTime.of(8, 30), arrival.arrivalTime()),
                () -> assertNull(arrival.departureTime()),
                () -> assertNull(departure.arrivalTime()),
                () -> assertEquals(LocalTime.of(16, 15), departure.departureTime()),
                // both legs carry the same people
                () -> assertEquals(arrival.drivers(), departure.drivers()),
                () -> assertEquals(arrival.passengers(), departure.passengers())
        );
    }

    @Test
    void shouldReturnEachRoundTripLegOnceForTheCreatorOnceAnAgreementExists() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        UUID roundTripId = UUID.randomUUID();
        UUID arrivalId = data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "OPEN", roundTripId, DayOfWeek.MONDAY);
        data.insertOffer(owner, "Steinbach", "DEPARTURE", null, LocalTime.of(16, 15),
                "OPEN", roundTripId, DayOfWeek.MONDAY);
        long agreementId = data.insertAgreementForOffer(arrivalId);
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        List<RideAgreementSummary> results = repository.findByMemberEmail(owner);

        // Two tickets (arrival + departure), not four.
        assertEquals(2, results.size());
    }

    @Test
    void shouldReturnUnjoinedRoundTripLegsSeparately() {
        String owner = data.createUser("Olive", "Owner");
        UUID roundTripId = UUID.randomUUID();
        data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "OPEN", roundTripId, DayOfWeek.MONDAY);
        data.insertOffer(owner, "Steinbach", "DEPARTURE", null, LocalTime.of(16, 15),
                "OPEN", roundTripId, DayOfWeek.MONDAY);

        List<RideAgreementSummary> results = repository.findByMemberEmail(owner);

        assertEquals(2, results.size());
        assertAll(
                () -> assertNull(results.get(0).id()),
                () -> assertNull(results.get(1).id()),
                () -> assertEquals(roundTripId, results.get(0).roundTripId()),
                () -> assertEquals(roundTripId, results.get(1).roundTripId()),
                () -> assertNotNull(legOfType(results, "ARRIVAL")),
                () -> assertNotNull(legOfType(results, "DEPARTURE"))
        );
    }

    @Test
    void shouldReturnOnlyTheLinkedLegWhenTheOtherRoundTripLegIsMissing() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        // Has a round_trip_id, but its paired leg does not exist.
        UUID arrivalId = data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "OPEN", UUID.randomUUID(), DayOfWeek.MONDAY);
        long agreementId = data.insertAgreementForOffer(arrivalId);
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        List<RideAgreementSummary> results = repository.findByMemberEmail(joiner);

        assertEquals(1, results.size());
        assertEquals(arrivalId, results.get(0).listingId());
    }

    @Test
    void shouldNotReturnAnotherUsersAgreements() {
        String owner = data.createUser("Olive", "Owner");
        String joiner = data.createUser("Jo", "Joiner");
        String stranger = data.createUser("Sam", "Stranger");
        long agreementId = data.insertAgreementForOffer(data.simpleOffer(owner));
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, joiner, "PASSENGER");

        assertTrue(repository.findByMemberEmail(stranger).isEmpty());
    }

    @Test
    void shouldPassThroughTheListingStatusForFullAndArchivedAgreements() {
        String owner = data.createUser("Olive", "Owner");
        String fullJoiner = data.createUser("Fay", "Full");
        String archivedJoiner = data.createUser("Ari", "Archived");

        UUID fullOffer = data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "FULL", null, DayOfWeek.MONDAY);
        long fullAgreement = data.insertAgreementForOffer(fullOffer);
        data.addMember(fullAgreement, owner, "DRIVER");
        data.addMember(fullAgreement, fullJoiner, "PASSENGER");

        UUID archivedOffer = data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
                "ARCHIVED", null, DayOfWeek.TUESDAY);
        long archivedAgreement = data.insertAgreementForOffer(archivedOffer);
        data.addMember(archivedAgreement, owner, "DRIVER");
        data.addMember(archivedAgreement, archivedJoiner, "PASSENGER");

        assertAll(
                () -> assertEquals("FULL", repository.findByMemberEmail(fullJoiner).get(0).status()),
                // an archived ride still shows for the members who were in it
                () -> assertEquals("ARCHIVED", repository.findByMemberEmail(archivedJoiner).get(0).status())
        );
    }

    @Test
    void shouldOrderMembersByName() {
        String owner = data.createUser("Olive", "Owner");
        String zed = data.createUser("Zed", "Zulu");
        String amy = data.createUser("Amy", "Able");
        long agreementId = data.insertAgreementForOffer(data.simpleOffer(owner));
        data.addMember(agreementId, owner, "DRIVER");
        data.addMember(agreementId, zed, "PASSENGER");
        data.addMember(agreementId, amy, "PASSENGER");

        RideAgreementSummary ticket = repository.findByMemberEmail(owner).get(0);

        assertEquals(
                List.of("Amy", "Zed"),
                ticket.passengers().stream().map(AgreementMember::firstName).toList()
        );
    }

    // EXPECTED TO FAIL until findOwnListingsWithoutAgreement filters out archived listings, but maybe we dont want this
    // When an owner deletes a listing nobody joined, it still shows up on their dashboard currently
    // @Test
    // void shouldNotReturnOwnArchivedListingThatNobodyJoined() {
    //     String owner = data.createUser("Olive", "Owner");
    //     data.insertOffer(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
    //             "ARCHIVED", null, DayOfWeek.MONDAY);
    //     data.insertRequest(owner, "Steinbach", "ARRIVAL", LocalTime.of(8, 30), null,
    //             "ARCHIVED", null, DayOfWeek.MONDAY);

    //     assertTrue(repository.findByMemberEmail(owner).isEmpty());
    // }
}