package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideOfferService;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ManageRideOfferController.class, properties = {
        "spring.config.import=", "gobison.auth.allowed-origins=http://localhost:3000"
})
@Import({SecurityConfiguration.class, ManageRideOfferService.class})
class ManageRideOfferControllerTest {

    private static final String OWNER = "owner@myumanitoba.ca";
    private static final String OTHER = "other@myumanitoba.ca";
    private static final String URL = "/api/v1/rides/offers/{offerId}";
    private final UUID offerId = UUID.randomUUID();
    private final UUID roundTripId = UUID.randomUUID();

    @Autowired private MockMvc mvc;
    @MockitoBean private UserRepository users;
    @MockitoBean private RideOfferRepository offers;

    @Test
    void ownerCanLoadOfferDetailsForEditing() throws Exception {
        account(OWNER, true);
        givenOffer();

        mvc.perform(get(URL, offerId).with(user(OWNER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.offerId").value(offerId.toString()))
                .andExpect(jsonPath("$.roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$.rideType").value("departing"))
                .andExpect(jsonPath("$.departureTime").value("17:30"))
                .andExpect(jsonPath("$.passengerNum").value(3))
                .andExpect(jsonPath("$.askingForDrivers").value(true));
    }

    @Test
    void anotherUserCannotLoadTheOffer() throws Exception {
        account(OTHER, true);
        givenOffer();
        mvc.perform(get(URL, offerId).with(user(OTHER))).andExpect(status().isForbidden());
    }

    @Test
    void unverifiedOwnerIsRejected() throws Exception {
        account(OWNER, false);
        mvc.perform(get(URL, offerId).with(user(OWNER))).andExpect(status().isForbidden());
        verifyNoInteractions(offers);
    }

    @Test
    void missingOfferReturnsNotFound() throws Exception {
        account(OWNER, true);
        when(offers.findById(offerId)).thenReturn(Optional.empty());
        mvc.perform(get(URL, offerId).with(user(OWNER))).andExpect(status().isNotFound());
    }

    @Test
    void loginIsRequired() throws Exception {
        mvc.perform(get(URL, offerId)).andExpect(status().isUnauthorized());
        verifyNoInteractions(users, offers);
    }

    @Test
    void sessionWithUnknownAccountIsRejected() throws Exception {
        when(users.findByEmail(OWNER)).thenReturn(Optional.empty());
        mvc.perform(get(URL, offerId).with(user(OWNER))).andExpect(status().isUnauthorized());
        verifyNoInteractions(offers);
    }

    private void account(String email, boolean verified) {
        when(users.findByEmail(email)).thenReturn(Optional.of(
                new User(email, "test-password", "Test", "User", verified)));
    }

    private void givenOffer() {
        var offer = new RideOffer(RideType.DEPARTURE, LocalTime.of(17, 30), roundTripId,
                offerId, OWNER, "Winnipeg", "123 Main Street", null, Set.of(DayOfWeek.MONDAY),
                "Test ride", "OPEN", 3, true);
        when(offers.findById(offerId)).thenReturn(Optional.of(offer));
    }
}
