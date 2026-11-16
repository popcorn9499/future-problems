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

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ManageRideRequestServiceTest {

    private static final String OWNER = "owner@myumanitoba.ca";
    private static final String OTHER = "other@myumanitoba.ca";
    private static final UUID REQUEST_ID = UUID.randomUUID();

    @Mock
    private UserRepository userRepository;

    @Mock
    private RideRequestRepository rideRequestRepository;

    private ManageRideRequestService service;

    @BeforeEach
    void setUp() {
        service = new ManageRideRequestService(
                userRepository, rideRequestRepository);
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