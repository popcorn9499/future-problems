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

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ManageRideRequestController.class, properties = {
        "spring.config.import=",
        "gobison.auth.allowed-origins=http://localhost:3000"
})
@Import({ SecurityConfiguration.class, ManageRideRequestService.class })
class RoundTripRideRequestControllerTest {

    private static final String OWNER = "owner@myumanitoba.ca";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private RideRequestRepository rideRequestRepository;

    @MockitoBean
    private Geocoder geocoder;

    @Test
    void ownerCanUpdateBothLegsFromTheReturnLeg() throws Exception {
        UUID roundTripId = UUID.randomUUID();
        UUID arrivalId = UUID.randomUUID();
        UUID departureId = UUID.randomUUID();
        var arrival = leg(arrivalId, roundTripId, RideType.ARRIVAL);
        var departure = leg(departureId, roundTripId, RideType.DEPARTURE);

        when(userRepository.findByEmail(OWNER))
                .thenReturn(Optional.of(new User(OWNER, "test-password", "Ride", "Owner", true)));
        when(rideRequestRepository.findById(departureId))
                .thenReturn(Optional.of(departure));
        when(rideRequestRepository.hasOtherParticipants(departureId))
                .thenReturn(false);
        when(rideRequestRepository.findRoundTripLegs(roundTripId, OWNER))
                .thenReturn(List.of(departure, arrival));
        when(rideRequestRepository.update(any(RideRequest.class)))
                .thenAnswer(call -> Optional.of(call.getArgument(0, RideRequest.class)));

        mvc.perform(patch("/api/v1/rides/requests/{requestId}/round-trip", departureId)
                        .with(user(OWNER))
                        .contentType("application/json")
                        .content("""
                                {
                                  "city": "Winnipeg",
                                  "streetAddress": "123 Main Street",
                                  "arrivalTime": "08:30",
                                  "departureTime": "17:30",
                                  "daysOfWeek": ["MONDAY"],
                                  "description": "Test ride"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].requestId").value(arrivalId.toString()))
                .andExpect(jsonPath("$[0].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$[0].arrivalTime").value("08:30"))
                .andExpect(jsonPath("$[0].departureTime").value(nullValue()))
                .andExpect(jsonPath("$[1].requestId").value(departureId.toString()))
                .andExpect(jsonPath("$[1].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$[1].departureTime").value("17:30"))
                .andExpect(jsonPath("$[1].arrivalTime").value(nullValue()));

        verify(rideRequestRepository, times(2)).update(any(RideRequest.class));
    }

    private RideRequest leg(UUID requestId, UUID roundTripId, RideType type) {
        return new RideRequest(
                type,
                type == RideType.DEPARTURE ? LocalTime.of(17, 0) : null,
                roundTripId,
                requestId,
                OWNER,
                "Winnipeg",
                "123 Main Street",
                type == RideType.ARRIVAL ? LocalTime.of(8, 0) : null,
                Set.of(DayOfWeek.MONDAY),
                "Test ride",
                "OPEN");
    }
}