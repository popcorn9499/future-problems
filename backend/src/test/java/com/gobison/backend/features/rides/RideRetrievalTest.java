package com.gobison.backend.features.rides;

import com.gobison.backend.features.rides.application.CreateRideOfferService;
import com.gobison.backend.features.rides.application.CreateRideRequestService;
import com.gobison.backend.features.rides.application.GetRideRequestsService;
import com.gobison.backend.features.rides.application.RetrieveRideOffersService;
import com.gobison.backend.features.rides.domain.model.GeoLocation;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.rides.presentation.RideOfferController;
import com.gobison.backend.features.rides.presentation.RideRequestController;
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
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = {RideRequestController.class, RideOfferController.class},
        properties = "spring.config.import=")
@Import({SecurityConfiguration.class, RetrieveRideOffersService.class, GetRideRequestsService.class})
class RideRetrievalTest {

    @Autowired
    MockMvc mvc;

    @MockitoBean
    UserRepository userRepository;

    @MockitoBean
    RideRequestRepository rideRequestRepository;

    @MockitoBean
    RideOfferRepository rideOfferRepository;

    // The controllers also depend on the create services; they are not under test here.
    @MockitoBean
    CreateRideOfferService createRideOfferService;

    @MockitoBean
    CreateRideRequestService createRideRequestService;

    private final String email = "ada@myumanitoba.ca";
    private final GeoLocation location = new GeoLocation(-97.138, 49.895);

    private void account(boolean verified) {
        when(userRepository.findByEmail(email))
                .thenReturn(Optional.of(new User(email, "secret", "Ada", "Lovelace", verified)));
    }

    // Build these BEFORE stubbing a repository call: creating a mock inside another when(...) fails.
    private RideOffer offer(RideType type, UUID roundTripId) {
        RideOffer offer = mock(RideOffer.class);
        when(offer.getOfferId()).thenReturn(UUID.randomUUID());
        when(offer.getRideType()).thenReturn(type);
        when(offer.getRoundTripId()).thenReturn(roundTripId);
        when(offer.getUserId()).thenReturn("driver@myumanitoba.ca");
        when(offer.getCity()).thenReturn("Winnipeg");
        when(offer.getStreetAddress()).thenReturn("123 Main");
        when(offer.getArrivalTime()).thenReturn(LocalTime.of(8, 30));
        when(offer.getDepartureTime()).thenReturn(LocalTime.of(16, 30));
        when(offer.getDaysOfWeek()).thenReturn(Set.of(DayOfWeek.FRIDAY, DayOfWeek.MONDAY));
        when(offer.getDescription()).thenReturn("Leaving from Fort Garry");
        when(offer.getStatus()).thenReturn("OPEN");
        when(offer.getPassengerNum()).thenReturn(3);
        when(offer.isAskingForDrivers()).thenReturn(false);
        when(offer.getLocation()).thenReturn(location);
        return offer;
    }

    private RideRequest request(RideType type, UUID roundTripId) {
        RideRequest request = mock(RideRequest.class);
        when(request.getRequestId()).thenReturn(UUID.randomUUID());
        when(request.getRideType()).thenReturn(type);
        when(request.getRoundTripId()).thenReturn(roundTripId);
        when(request.getUserId()).thenReturn("rider@myumanitoba.ca");
        when(request.getCity()).thenReturn("Winnipeg");
        when(request.getStreetAddress()).thenReturn("66 Chancellors Cir");
        when(request.getArrivalTime()).thenReturn(LocalTime.of(8, 30));
        when(request.getDepartureTime()).thenReturn(LocalTime.of(16, 30));
        when(request.getDaysOfWeek()).thenReturn(Set.of(DayOfWeek.WEDNESDAY, DayOfWeek.TUESDAY));
        when(request.getDescription()).thenReturn("Need a ride to campus");
        when(request.getStatus()).thenReturn("OPEN");
        when(request.getLocation()).thenReturn(location);
        return request;
    }

    @Test
    void rejectsUnauthenticatedUnverifiedAndDeletedUsers() throws Exception {
        for (String path : new String[] {"requests", "offers"}) {
            mvc.perform(get("/api/v1/rides/" + path))
                    .andExpect(status().isUnauthorized());
        }

        account(false);
        for (String path : new String[] {"requests", "offers"}) {
            mvc.perform(get("/api/v1/rides/" + path).with(user(email)))
                    .andExpect(status().isForbidden());
        }

        when(userRepository.findByEmail(email)).thenReturn(Optional.empty());
        for (String path : new String[] {"requests", "offers"}) {
            mvc.perform(get("/api/v1/rides/" + path).with(user(email)))
                    .andExpect(status().isUnauthorized());
        }

        verifyNoInteractions(rideRequestRepository, rideOfferRepository);
    }

    @Test
    void appliesDefaultFiltersAndExcludesCurrentUser() throws Exception {
        account(true);

        mvc.perform(get("/api/v1/rides/offers").with(user(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.offers").isArray())
                .andExpect(jsonPath("$.offers").isEmpty());
        verify(rideOfferRepository).findFilteredOffers(
                email, null, List.of(), null, null, null, null, "OPEN");

        mvc.perform(get("/api/v1/rides/requests").with(user(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.requests").isArray())
                .andExpect(jsonPath("$.requests").isEmpty());
        verify(rideRequestRepository).findFiltered(
                email, null, List.of(), null, null, null, "OPEN");
    }

    @Test
    void includesOwnListingsOnlyWhenRequestedAndKeepsBrowseFilters() throws Exception {
        account(true);

        mvc.perform(get("/api/v1/rides/offers").with(user(email))
                        .param("includeOwn", "true").param("city", "Winnipeg"))
                .andExpect(status().isOk());
        verify(rideOfferRepository).findFilteredOffers(
                null, "Winnipeg", List.of(), null, null, null, null, "OPEN");

        mvc.perform(get("/api/v1/rides/requests").with(user(email))
                        .param("includeOwn", "true").param("city", "Winnipeg"))
                .andExpect(status().isOk());
        verify(rideRequestRepository).findFiltered(
                null, "Winnipeg", List.of(), null, null, null, "OPEN");
    }

    @Test
    void ignoresLegacyClosedStatusOnBothBrowseEndpoints() throws Exception {
        account(true);

        mvc.perform(get("/api/v1/rides/offers").with(user(email))
                        .param("status", "CLOSED"))
                .andExpect(status().isOk());
        verify(rideOfferRepository).findFilteredOffers(
                email, null, List.of(), null, null, null, null, "OPEN");

        mvc.perform(get("/api/v1/rides/requests").with(user(email))
                        .param("status", "CLOSED"))
                .andExpect(status().isOk());
        verify(rideRequestRepository).findFiltered(
                email, null, List.of(), null, null, null, "OPEN");
    }

    @Test
    void treatsBlankParamsAsUnset() throws Exception {
        account(true);

        mvc.perform(get("/api/v1/rides/offers").with(user(email))
                        .param("daysOfWeek", " ")
                        .param("rideType", "")
                        .param("departureTime", " ")
                        .param("arrivalTime", ""))
                .andExpect(status().isOk());

        verify(rideOfferRepository).findFilteredOffers(
                email, null, List.of(), null, null, null, null, "OPEN");
    }

    @Test
    void parsesAndForwardsOfferFilters() throws Exception {
        account(true);

        mvc.perform(get("/api/v1/rides/offers").with(user(email))
                        .param("city", "Winnipeg")
                        .param("daysOfWeek", "monday, FRIDAY,")
                        .param("rideType", " Arriving ")
                        .param("departureTime", "16:30")
                        .param("arrivalTime", " 08:30 "))
                .andExpect(status().isOk());

        verify(rideOfferRepository).findFilteredOffers(
                email,
                "Winnipeg",
                List.of(DayOfWeek.MONDAY, DayOfWeek.FRIDAY),
                RideType.ARRIVAL,
                null,
                LocalTime.of(16, 30),
                LocalTime.of(8, 30),
                "OPEN");
    }

    @Test
    void mapsOfferRideTypeAliases() throws Exception {
        account(true);

        Map<String, RideType> oneWay = Map.of(
                "arriving", RideType.ARRIVAL,
                "arrival", RideType.ARRIVAL,
                "departing", RideType.DEPARTURE,
                "DEPARTURE", RideType.DEPARTURE);

        for (var entry : oneWay.entrySet()) {
            clearInvocations(rideOfferRepository);
            mvc.perform(get("/api/v1/rides/offers").with(user(email))
                            .param("rideType", entry.getKey()))
                    .andExpect(status().isOk());
            verify(rideOfferRepository).findFilteredOffers(
                    email, null, List.of(), entry.getValue(), null, null, null, "OPEN");
        }

        // Round trip is filtered by roundTripId presence, not by RideType
        for (String roundTrip : new String[] {"roundTrip", "round_trip", "ROUNDTRIP"}) {
            clearInvocations(rideOfferRepository);
            mvc.perform(get("/api/v1/rides/offers").with(user(email))
                            .param("rideType", roundTrip))
                    .andExpect(status().isOk());
            verify(rideOfferRepository).findFilteredOffers(
                    email, null, List.of(), null, true, null, null, "OPEN");
        }
    }

    @Test
    void parsesAndForwardsRequestFilters() throws Exception {
        account(true);

        mvc.perform(get("/api/v1/rides/requests").with(user(email))
                        .param("city", "Winnipeg")
                        .param("daysOfWeek", "saturday,SUNDAY")
                        .param("rideType", "departure")
                        .param("departureTime", "16:30"))
                .andExpect(status().isOk());

        // Default times(1) also guards against the controller querying twice
        verify(rideRequestRepository).findFiltered(
                email,
                "Winnipeg",
                List.of(DayOfWeek.SATURDAY, DayOfWeek.SUNDAY),
                RideType.DEPARTURE,
                LocalTime.of(16, 30),
                null,
                "OPEN");
    }

    @Test
    void rejectsInvalidFiltersForBothEndpoints() throws Exception {
        account(true);

        String[][] invalidParams = {
                {"daysOfWeek", "FUNDAY"},
                {"daysOfWeek", "MONDAY,FUNDAY"},
                {"rideType", "unknown"},
                {"departureTime", "8:30"},
                {"departureTime", "bad"},
                {"arrivalTime", "24:00"},
                {"arrivalTime", "08:30pm"}};

        for (String path : new String[] {"requests", "offers"}) {
            for (String[] param : invalidParams) {
                mvc.perform(get("/api/v1/rides/" + path).with(user(email))
                                .param(param[0], param[1]))
                        .andExpect(status().isBadRequest());
            }
        }

        verifyNoInteractions(rideRequestRepository, rideOfferRepository);
    }

    @Test
    void groupsRoundTripOffersAndKeepsSingleLegsSeparate() throws Exception {
        account(true);
        UUID roundTripId = UUID.randomUUID();
        RideOffer single = offer(RideType.ARRIVAL, null);
        RideOffer arrivalLeg = offer(RideType.ARRIVAL, roundTripId);
        RideOffer departureLeg = offer(RideType.DEPARTURE, roundTripId);
        List<RideOffer> offers = List.of(departureLeg, single, arrivalLeg);
        when(single.getUserId()).thenReturn("missing@myumanitoba.ca");
        var poster = new User("driver@myumanitoba.ca", "secret", "Jordan", "Lee", true);
        poster.setAvatarColor("#D1C4E9");
        var ownerEmails = List.of("driver@myumanitoba.ca", "missing@myumanitoba.ca");
        when(userRepository.findAllByEmail(ownerEmails)).thenReturn(Map.of(poster.getEmail(), poster));
        when(rideOfferRepository.findFilteredOffers(any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(offers);

        mvc.perform(get("/api/v1/rides/offers").with(user(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.offers", hasSize(2)))
                // Single legs are listed before round trips
                .andExpect(jsonPath("$.offers[0].rideType").value("arriving"))
                .andExpect(jsonPath("$.offers[0].offerId").value(single.getOfferId().toString()))
                .andExpect(jsonPath("$.offers[0].arrivalId").value(single.getOfferId().toString()))
                .andExpect(jsonPath("$.offers[0].departureId").value(nullValue()))
                .andExpect(jsonPath("$.offers[0].roundTripId").value(nullValue()))
                .andExpect(jsonPath("$.offers[0].arrivalTime").value("08:30"))
                .andExpect(jsonPath("$.offers[0].poster").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.offers[0].departureTime").value(nullValue()))
                .andExpect(jsonPath("$.offers[0].daysOfWeek[0]").value("MONDAY"))
                .andExpect(jsonPath("$.offers[0].passengerNum").value(3))
                .andExpect(jsonPath("$.offers[0].askingForDrivers").value(false))
                // Round trip collapsed into one summary
                .andExpect(jsonPath("$.offers[1].rideType").value("roundTrip"))
                .andExpect(jsonPath("$.offers[1].offerId").value(nullValue()))
                .andExpect(jsonPath("$.offers[1].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$.offers[1].arrivalId").value(arrivalLeg.getOfferId().toString()))
                .andExpect(jsonPath("$.offers[1].departureId").value(departureLeg.getOfferId().toString()))
                .andExpect(jsonPath("$.offers[1].arrivalTime").value("08:30"))
                .andExpect(jsonPath("$.offers[1].departureTime").value("16:30"))
                .andExpect(jsonPath("$.offers[1].city").value("Winnipeg"))
                .andExpect(jsonPath("$.offers[1].poster.firstName").value("Jordan"))
                .andExpect(jsonPath("$.offers[1].poster.lastName").value("Lee"))
                .andExpect(jsonPath("$.offers[1].poster.avatarColor").value("#D1C4E9"))
                .andExpect(jsonPath("$.offers[1].poster.email").doesNotHaveJsonPath());
        verify(userRepository).findAllByEmail(ownerEmails);
    }

    @Test
    void groupsRoundTripRequestsAndKeepsSingleLegsSeparate() throws Exception {
        account(true);
        UUID roundTripId = UUID.randomUUID();
        RideRequest single = request(RideType.DEPARTURE, null);
        RideRequest arrivalLeg = request(RideType.ARRIVAL, roundTripId);
        RideRequest departureLeg = request(RideType.DEPARTURE, roundTripId);
        List<RideRequest> requests = List.of(arrivalLeg, departureLeg, single);
        when(single.getUserId()).thenReturn("missing@myumanitoba.ca");
        var poster = new User("rider@myumanitoba.ca", "secret", "Jordan", "Lee", true);
        poster.setAvatarColor("#D1C4E9");
        var ownerEmails = List.of("rider@myumanitoba.ca", "missing@myumanitoba.ca");
        when(userRepository.findAllByEmail(ownerEmails)).thenReturn(Map.of(poster.getEmail(), poster));
        when(rideRequestRepository.findFiltered(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(requests);

        mvc.perform(get("/api/v1/rides/requests").with(user(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.requests", hasSize(2)))
                .andExpect(jsonPath("$.requests[0].rideType").value("departing"))
                .andExpect(jsonPath("$.requests[0].requestId").value(single.getRequestId().toString()))
                .andExpect(jsonPath("$.requests[0].departureId").value(single.getRequestId().toString()))
                .andExpect(jsonPath("$.requests[0].arrivalId").value(nullValue()))
                .andExpect(jsonPath("$.requests[0].arrivalTime").value(nullValue()))
                .andExpect(jsonPath("$.requests[0].poster").doesNotHaveJsonPath())
                .andExpect(jsonPath("$.requests[0].departureTime").value("16:30"))
                .andExpect(jsonPath("$.requests[0].daysOfWeek[0]").value("TUESDAY"))
                .andExpect(jsonPath("$.requests[1].rideType").value("roundTrip"))
                .andExpect(jsonPath("$.requests[1].requestId").value(nullValue()))
                .andExpect(jsonPath("$.requests[1].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$.requests[1].arrivalId").value(arrivalLeg.getRequestId().toString()))
                .andExpect(jsonPath("$.requests[1].departureId").value(departureLeg.getRequestId().toString()))
                .andExpect(jsonPath("$.requests[1].arrivalTime").value("08:30"))
                .andExpect(jsonPath("$.requests[1].departureTime").value("16:30"))
                .andExpect(jsonPath("$.requests[1].poster.firstName").value("Jordan"))
                .andExpect(jsonPath("$.requests[1].poster.lastName").value("Lee"))
                .andExpect(jsonPath("$.requests[1].poster.avatarColor").value("#D1C4E9"))
                .andExpect(jsonPath("$.requests[1].poster.email").doesNotHaveJsonPath());
        verify(userRepository).findAllByEmail(ownerEmails);
    }
}
