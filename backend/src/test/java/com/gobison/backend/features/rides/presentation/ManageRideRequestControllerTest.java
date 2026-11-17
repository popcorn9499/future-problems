package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideRequestService;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import com.gobison.backend.features.rides.application.geocoding.Geocoder;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ManageRideRequestController.class, properties = {
        "spring.config.import=",
        "gobison.auth.allowed-origins=http://localhost:3000"
})
@Import({ SecurityConfiguration.class, ManageRideRequestService.class })
class ManageRideRequestControllerTest {

    private static final String OWNER = "owner@myumanitoba.ca";
    private static final String OTHER = "other@myumanitoba.ca";
    private static final UUID REQUEST_ID = UUID.randomUUID();
    private static final String URL = "/api/v1/rides/requests/";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private RideRequestRepository rideRequestRepository;

    @MockitoBean
    private Geocoder geocoder;

    @Test
    void ownerCanReadOwnRequest() throws Exception {
        account(OWNER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(ownedRequest()));

        mvc.perform(get(URL + REQUEST_ID).with(user(OWNER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.requestId").value(REQUEST_ID.toString()))
                .andExpect(jsonPath("$.roundTripId").value(nullValue()))
                .andExpect(jsonPath("$.rideType").value("arriving"))
                .andExpect(jsonPath("$.city").value("Winnipeg"))
                .andExpect(jsonPath("$.streetAddress").value("123 Main Street"))
                .andExpect(jsonPath("$.arrivalTime").value("08:00"))
                .andExpect(jsonPath("$.departureTime").value(nullValue()))
                .andExpect(jsonPath("$.daysOfWeek.length()").value(2))
                .andExpect(jsonPath("$.daysOfWeek[0]").value("MONDAY"))
                .andExpect(jsonPath("$.daysOfWeek[1]").value("FRIDAY"))
                .andExpect(jsonPath("$.description").value("Test ride"))
                .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void unauthenticatedUserIsRejected() throws Exception {
        mvc.perform(get(URL + REQUEST_ID))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(userRepository, rideRequestRepository);
    }

    @Test
    void anotherUserCannotReadOwnersRequest() throws Exception {
        account(OTHER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(ownedRequest()));

        mvc.perform(get(URL + REQUEST_ID).with(user(OTHER)))
                .andExpect(status().isForbidden());
    }

    @Test
    void unverifiedUserIsRejected() throws Exception {
        account(OWNER, false);

        mvc.perform(get(URL + REQUEST_ID).with(user(OWNER)))
                .andExpect(status().isForbidden());

        verifyNoInteractions(rideRequestRepository);
    }

    @Test
    void missingRequestReturnsNotFound() throws Exception {
        account(OWNER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.empty());

        mvc.perform(get(URL + REQUEST_ID).with(user(OWNER)))
                .andExpect(status().isNotFound());
    }

    @Test
    void invalidRequestIdReturnsBadRequest() throws Exception {
        mvc.perform(get(URL + "not-a-uuid").with(user(OWNER)))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(userRepository, rideRequestRepository);
    }

    private void account(String email, boolean verified) {
        when(userRepository.findByEmail(email))
                .thenReturn(Optional.of(
                        new User(email, "test-password", "Test", "User", verified)));
    }

    private RideRequest ownedRequest() {
        return new RideRequest(
                RideType.ARRIVAL,
                null,
                null,
                REQUEST_ID,
                OWNER,
                "Winnipeg",
                "123 Main Street",
                LocalTime.of(8, 0),
                Set.of(DayOfWeek.FRIDAY, DayOfWeek.MONDAY),
                "Test ride",
                "OPEN");
    }
}