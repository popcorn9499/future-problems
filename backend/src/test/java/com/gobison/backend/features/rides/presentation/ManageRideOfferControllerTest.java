package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideOfferService;
import com.gobison.backend.features.rides.application.geocoding.Geocoder;
import com.gobison.backend.features.rides.domain.model.GeoLocation;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository.CancellationResult;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
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
    @MockitoBean private Geocoder geocoder;
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

    @Test
    void ownerEditsBothLegsFromDepartureId() throws Exception {
        account(OWNER, true);
        var arrivalId = givenRoundTrip();
        when(offers.updateIfEditable(eq(OWNER), anyList()))
                .thenAnswer(call -> Optional.of(call.<List<RideOffer>>getArgument(1)));

        patchOffer(OWNER, true)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.arrivalId").value(arrivalId.toString()))
                .andExpect(jsonPath("$.departureId").value(offerId.toString()))
                .andExpect(jsonPath("$.arrivalTime").value("08:30"))
                .andExpect(jsonPath("$.departureTime").value("18:00"))
                .andExpect(jsonPath("$.passengerNum").value(4))
                .andExpect(jsonPath("$.askingForDrivers").value(false));
        verifyNoInteractions(geocoder);
    }

    @Test
    void ownerEditsOneWayOffer() throws Exception {
        account(OWNER, true);
        givenOffer(null);
        when(offers.updateIfEditable(eq(OWNER), anyList()))
                .thenAnswer(call -> Optional.of(call.<List<RideOffer>>getArgument(1)));

        patchOffer(OWNER, false).andExpect(status().isOk())
                .andExpect(jsonPath("$.offerId").value(offerId.toString()))
                .andExpect(jsonPath("$.departureTime").value("18:00"));
    }

    @Test
    void ownerMovesBothOfferPinsWithoutChangingAddressText() throws Exception {
        account(OWNER, true);
        givenRoundTrip();
        when(offers.updateIfEditable(eq(OWNER), anyList())).thenAnswer(call -> {
            List<RideOffer> legs = call.getArgument(1);
            assertEquals(List.of(new GeoLocation(-97.12, 49.88), new GeoLocation(-97.12, 49.88)),
                    legs.stream().map(RideOffer::getLocation).toList());
            return Optional.of(legs);
        });

        mvc.perform(patch(URL, offerId).with(user(OWNER)).contentType("application/json").content("""
                {"city":"Winnipeg","streetAddress":"123 Main Street","departureTime":"18:00",
                 "arrivalTime":"08:30","daysOfWeek":["FRIDAY"],"passengerNum":4,"askingForDrivers":false,
                 "location":{"latitude":49.88,"longitude":-97.12}}
                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.location.latitude").value(49.88));
        verifyNoInteractions(geocoder);
    }

    @Test
    void otherUserCannotEditOffer() throws Exception {
        account(OTHER, true);
        givenOffer();
        patchOffer(OTHER, true).andExpect(status().isForbidden());
        verify(offers, never()).updateIfEditable(anyString(), anyList());
        verifyNoInteractions(geocoder);
    }

    @Test
    void editConflictReturns409() throws Exception {
        account(OWNER, true);
        givenOffer(null);
        when(offers.updateIfEditable(eq(OWNER), anyList())).thenReturn(Optional.empty());
        patchOffer(OWNER, false).andExpect(status().isConflict());
        verify(offers).updateIfEditable(eq(OWNER), anyList());
    }

    @Test
    void ownerCancelsOneWayOffer() throws Exception {
        account(OWNER, true);
        givenOffer(null);
        when(offers.cancelForOwner(OWNER, List.of(offerId), false)).thenReturn(CancellationResult.CANCELLED);

        mvc.perform(delete(URL, offerId).with(user(OWNER))).andExpect(status().isNoContent());
        verify(offers).cancelForOwner(OWNER, List.of(offerId), false);
    }

    @Test
    void confirmsParticipantsBeforeCancellingBothLegs() throws Exception {
        account(OWNER, true);
        var ids = List.of(offerId, givenRoundTrip());
        when(offers.cancelForOwner(OWNER, ids, false)).thenReturn(CancellationResult.CONFIRMATION_REQUIRED);
        when(offers.cancelForOwner(OWNER, ids, true)).thenReturn(CancellationResult.CANCELLED);

        mvc.perform(delete(URL, offerId).with(user(OWNER)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONFIRMATION_REQUIRED"));
        mvc.perform(delete(URL, offerId).with(user(OWNER)).param("confirmParticipants", "true"))
                .andExpect(status().isNoContent());
        verify(offers).cancelForOwner(OWNER, ids, true);
    }

    @Test
    void loginAndOwnershipAreRequiredToCancel() throws Exception {
        mvc.perform(delete(URL, offerId)).andExpect(status().isUnauthorized());
        account(OTHER, true);
        givenOffer(null);
        mvc.perform(delete(URL, offerId).with(user(OTHER)).param("confirmParticipants", "true"))
                .andExpect(status().isForbidden());
        verify(offers, never()).cancelForOwner(anyString(), anyList(), anyBoolean());
    }

    @Test
    void changedOfferReturnsConflictWithoutConfirmationCode() throws Exception {
        account(OWNER, true);
        givenOffer(null);
        when(offers.cancelForOwner(OWNER, List.of(offerId), false)).thenReturn(CancellationResult.OFFER_CHANGED);
        mvc.perform(delete(URL, offerId).with(user(OWNER)))
                .andExpect(status().isConflict()).andExpect(content().string(""));
    }

    private UUID givenRoundTrip() {
        var departure = givenOffer();
        var arrivalId = UUID.randomUUID();
        var arrival = new RideOffer(RideType.ARRIVAL, null, roundTripId, arrivalId, OWNER,
                "Winnipeg", "123 Main Street", LocalTime.of(8, 0), Set.of(DayOfWeek.MONDAY),
                null, "OPEN", 3, true);
        when(offers.findRoundTripLegs(roundTripId, OWNER)).thenReturn(List.of(departure, arrival));
        return arrivalId;
    }

    private ResultActions patchOffer(String email, boolean roundTrip) throws Exception {
        var body = """
                {"city":"Winnipeg","streetAddress":"123 Main Street","departureTime":"18:00",
                 "arrivalTime":%s,"daysOfWeek":["FRIDAY"],"description":"Updated",
                 "passengerNum":4,"askingForDrivers":false}
                """.formatted(roundTrip ? "\"08:30\"" : "null");
        return mvc.perform(patch(URL, offerId).with(user(email)).contentType("application/json").content(body));
    }

    private void account(String email, boolean verified) {
        when(users.findByEmail(email)).thenReturn(Optional.of(
                new User(email, "test-password", "Test", "User", verified)));
    }

    private RideOffer givenOffer() {
        return givenOffer(roundTripId);
    }

    private RideOffer givenOffer(UUID tripId) {
        var offer = new RideOffer(RideType.DEPARTURE, LocalTime.of(17, 30), tripId,
                offerId, OWNER, "Winnipeg", "123 Main Street", null, Set.of(DayOfWeek.MONDAY),
                "Test ride", "OPEN", 3, true);
        when(offers.findById(offerId)).thenReturn(Optional.of(offer));
        return offer;
    }
}
