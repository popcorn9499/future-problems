package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.gobison.backend.features.rides.application.geocoding.Geocoder;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import com.gobison.backend.features.rides.domain.model.GeoLocation;
import com.gobison.backend.features.rides.presentation.UpdateRideRequestRequest;
import org.mockito.ArgumentCaptor;
import java.util.List;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class ManageRideRequestServiceTest {

    private static final String OWNER = "owner@myumanitoba.ca";
    private static final String OTHER = "other@myumanitoba.ca";
    private static final UUID REQUEST_ID = UUID.randomUUID();

    @Mock
    private UserRepository userRepository;

    @Mock
    private RideRequestRepository rideRequestRepository;

    @Mock
    private Geocoder geocoder;

    private ManageRideRequestService service;

    @BeforeEach
    void setUp() {
        service = new ManageRideRequestService(
                userRepository, rideRequestRepository, geocoder);
    }

    @Test
    void ownerCanReadOwnRequest() {
        givenUser(OWNER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(ownerRequest()));

        var result = service.getForOwner(OWNER, REQUEST_ID);

        assertEquals(REQUEST_ID, result.getRequestId());
        assertEquals(OWNER, result.getUserId());
    }

    @Test
    void anotherUserCannotReadOwnersRequest() {
        givenUser(OTHER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(ownerRequest()));

        var error = assertThrows(
                ResponseStatusException.class,
                () -> service.getForOwner(OTHER, REQUEST_ID));

        assertEquals(HttpStatus.FORBIDDEN, error.getStatusCode());
    }

    @Test
    void unknownUserIsRejected() {
        when(userRepository.findByEmail(OWNER))
                .thenReturn(Optional.empty());

        var error = assertThrows(
                ResponseStatusException.class,
                () -> service.getForOwner(OWNER, REQUEST_ID));

        assertEquals(HttpStatus.UNAUTHORIZED, error.getStatusCode());
        verifyNoInteractions(rideRequestRepository);
    }

    @Test
    void unverifiedUserIsRejected() {
        givenUser(OWNER, false);

        var error = assertThrows(
                ResponseStatusException.class,
                () -> service.getForOwner(OWNER, REQUEST_ID));

        assertEquals(HttpStatus.FORBIDDEN, error.getStatusCode());
        verifyNoInteractions(rideRequestRepository);
    }

    @Test
    void missingRequestReturnsNotFound() {
        givenUser(OWNER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.empty());

        var error = assertThrows(
                ResponseStatusException.class,
                () -> service.getForOwner(OWNER, REQUEST_ID));

        assertEquals(HttpStatus.NOT_FOUND, error.getStatusCode());
    }

    @Test
    void ownerCanEditWhenNobodyElseHasJoined() {
        givenUser(OWNER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(ownerRequest()));
        when(rideRequestRepository.hasOtherParticipants(REQUEST_ID))
                .thenReturn(false);

        var result = service.getForEdit(OWNER, REQUEST_ID);

        assertEquals(REQUEST_ID, result.getRequestId());
    }

    @Test
    void ownerCannotEditAfterAnotherUserJoins() {
        givenUser(OWNER, true);
        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(ownerRequest()));
        when(rideRequestRepository.hasOtherParticipants(REQUEST_ID))
                .thenReturn(true);

        var error = assertThrows(
                ResponseStatusException.class,
                () -> service.getForEdit(OWNER, REQUEST_ID));

        assertEquals(HttpStatus.CONFLICT, error.getStatusCode());
    }

    @Test
    void changingArrivalTimePreservesRequestIdAndLocation() {
        givenUser(OWNER, true);

        var current = ownerRequest();
        var originalLocation = new GeoLocation(-97.138, 49.895);
        current.setLocation(originalLocation);

        when(rideRequestRepository.findById(REQUEST_ID))
                .thenReturn(Optional.of(current));
        when(rideRequestRepository.hasOtherParticipants(REQUEST_ID))
                .thenReturn(false);
        when(rideRequestRepository.update(any(RideRequest.class)))
                .thenAnswer(call -> Optional.of(call.getArgument(0, RideRequest.class)));

        var form = new UpdateRideRequestRequest(
                current.getCity(),
                current.getStreetAddress(),
                "08:30",
                null,
                List.copyOf(current.getDaysOfWeek()),
                current.getDescription());

        service.updateOneWay(OWNER, REQUEST_ID, form);

        var captor = ArgumentCaptor.forClass(RideRequest.class);
        verify(rideRequestRepository).update(captor.capture());
        var sentToRepository = captor.getValue();

        assertEquals(LocalTime.of(8, 30), sentToRepository.getArrivalTime());
        assertEquals(REQUEST_ID, sentToRepository.getRequestId());
        assertEquals(originalLocation, sentToRepository.getLocation());
        verifyNoInteractions(geocoder);
    }

    @Test
    void cancellationDuringAddressLookupPreventsSavingTheEdit() {
        givenUser(OWNER, true);
        var current = ownerRequest();
        when(rideRequestRepository.findById(REQUEST_ID)).thenReturn(Optional.of(current));
        when(rideRequestRepository.lockForManagement(OWNER, Set.of(REQUEST_ID)))
                .thenReturn(Optional.of(RideRequestRepository.ManagementConflict.CANCELLED));
        var form = new UpdateRideRequestRequest(
                current.getCity(), "456 Main Street", "08:30", null,
                List.copyOf(current.getDaysOfWeek()), current.getDescription());

        var error = assertThrows(ResponseStatusException.class, () -> service.updateOneWay(OWNER, REQUEST_ID, form));

        assertEquals(HttpStatus.CONFLICT, error.getStatusCode());
        var order = inOrder(geocoder, rideRequestRepository);
        order.verify(geocoder).locate("456 Main Street", current.getCity());
        order.verify(rideRequestRepository).lockForManagement(OWNER, Set.of(REQUEST_ID));
        verify(rideRequestRepository, never()).update(any(RideRequest.class));
    }

    @Test
    void participantJoiningBetweenChecksPreventsSavingTheEdit() {
        givenUser(OWNER, true);
        var current = ownerRequest();
        when(rideRequestRepository.findById(REQUEST_ID)).thenReturn(Optional.of(current));
        when(rideRequestRepository.hasOtherParticipants(REQUEST_ID)).thenReturn(false, true);
        var form = new UpdateRideRequestRequest(
                current.getCity(), current.getStreetAddress(), "08:30", null,
                List.copyOf(current.getDaysOfWeek()), current.getDescription());

        var error = assertThrows(ResponseStatusException.class, () -> service.updateOneWay(OWNER, REQUEST_ID, form));

        assertEquals(HttpStatus.CONFLICT, error.getStatusCode());
        var order = inOrder(rideRequestRepository);
        order.verify(rideRequestRepository).hasOtherParticipants(REQUEST_ID);
        order.verify(rideRequestRepository).lockForManagement(OWNER, Set.of(REQUEST_ID));
        order.verify(rideRequestRepository).hasOtherParticipants(REQUEST_ID);
        verify(rideRequestRepository, never()).update(any(RideRequest.class));
    }

    private void givenUser(String email, boolean verified) {
        var user = new User(
                email, "test-password", "Test", "User", verified);

        when(userRepository.findByEmail(email))
                .thenReturn(Optional.of(user));
    }

    private RideRequest ownerRequest() {
        return new RideRequest(
                RideType.ARRIVAL,
                null,
                null,
                REQUEST_ID,
                OWNER,
                "Winnipeg",
                "123 Main Street",
                LocalTime.of(8, 0),
                Set.of(DayOfWeek.MONDAY),
                "Test ride",
                "OPEN");
    }
}