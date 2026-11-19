package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideRequestService;
import com.gobison.backend.features.rides.application.geocoding.Geocoder;
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

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ManageRideRequestController.class, properties = {
        "spring.config.import=",
        "gobison.auth.allowed-origins=http://localhost:3000"
})
@Import({ SecurityConfiguration.class, ManageRideRequestService.class })
class CancelRideRequestControllerTest {

    private static final String OWNER = "owner@myumanitoba.ca";
    private static final String URL = "/api/v1/rides/requests/{requestId}";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private UserRepository users;

    @MockitoBean
    private RideRequestRepository requests;

    @MockitoBean
    private Geocoder geocoder;

    @Test
    void ownerConfirmsBeforeBothLegsAreCancelled() throws Exception {
        var roundTripId = UUID.randomUUID();
        var arrival = leg(roundTripId, RideType.ARRIVAL);
        var departure = leg(roundTripId, RideType.DEPARTURE);
        var departureId = departure.getRequestId();
        var bothIds = Set.of(arrival.getRequestId(), departureId);

        givenVerifiedUser(OWNER);
        when(requests.findById(departureId)).thenReturn(Optional.of(departure));
        when(requests.findRoundTripLegs(roundTripId, OWNER)).thenReturn(List.of(departure, arrival));
        when(requests.hasOtherParticipants(departureId)).thenReturn(true);

        mvc.perform(delete(URL, departureId).with(user(OWNER)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONFIRMATION_REQUIRED"));

        verify(requests, never()).cancelForOwner(any(), any());

        when(requests.cancelForOwner(OWNER, bothIds)).thenReturn(true);

        mvc.perform(delete(URL, departureId)
                        .with(user(OWNER))
                        .param("confirmParticipants", "true"))
                .andExpect(status().isNoContent());

        verify(requests).cancelForOwner(OWNER, bothIds);
    }

    @Test
    void anotherUserCannotConfirmCancellation() throws Exception {
        String other = "other@myumanitoba.ca";
        var request = leg(null, RideType.ARRIVAL);
        givenVerifiedUser(other);
        when(requests.findById(request.getRequestId())).thenReturn(Optional.of(request));

        mvc.perform(delete(URL, request.getRequestId())
                        .with(user(other))
                        .param("confirmParticipants", "true"))
                .andExpect(status().isForbidden());

        verify(requests, never()).cancelForOwner(any(), any());
    }

    @Test
    void cancellationRequiresLogin() throws Exception {
        mvc.perform(delete(URL, UUID.randomUUID()))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(requests);
    }

    private void givenVerifiedUser(String email) {
        when(users.findByEmail(email))
                .thenReturn(Optional.of(new User(email, "test-password", "Test", "User", true)));
    }

    private RideRequest leg(UUID roundTripId, RideType type) {
        return new RideRequest(
                type,
                type == RideType.DEPARTURE ? LocalTime.of(17, 0) : null,
                roundTripId,
                UUID.randomUUID(),
                OWNER,
                "Winnipeg",
                "123 Main Street",
                type == RideType.ARRIVAL ? LocalTime.of(8, 0) : null,
                Set.of(DayOfWeek.MONDAY),
                "Test ride",
                "OPEN");
    }
}