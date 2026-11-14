package com.gobison.backend.features.dashboard.application;
 
import com.gobison.backend.features.dashboard.DashboardTestData;
import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.user.domain.repository.UserRepository;
 
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
 
import java.util.List;
import java.util.Locale;
import java.util.UUID;
 
import static org.junit.jupiter.api.Assertions.*;
 
/** Runs the real DashboardService against the real database. */
@SpringBootTest
class DashboardServiceIntegrationTest {
 
    @Autowired
    private DashboardService service;
 
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
 