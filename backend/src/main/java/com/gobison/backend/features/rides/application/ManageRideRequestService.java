package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.application.geocoding.Geocoder;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.presentation.UpdateRideRequestRequest;
import java.time.LocalTime;
import java.util.EnumSet;

import java.util.UUID;

@Service
public class ManageRideRequestService {

    private final UserRepository userRepository;
    private final RideRequestRepository rideRequestRepository;
    private final Geocoder geocoder;

    public ManageRideRequestService(
            UserRepository userRepository,
            RideRequestRepository rideRequestRepository,
            Geocoder geocoder) {
        this.userRepository = userRepository;
        this.rideRequestRepository = rideRequestRepository;
        this.geocoder = geocoder;
    }

    @Transactional(readOnly = true)
    public RideRequest getForOwner(String email, UUID requestId) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED));

        if (!user.isVerified()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Email verification required");
        }

        var rideRequest = rideRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Ride request not found"));

        if (!user.getEmail().equals(rideRequest.getUserId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You can only manage your own ride requests");
        }

        return rideRequest;
    }

    RideRequest getForEdit(String email, UUID requestId) {
        var rideRequest = getForOwner(email, requestId);

        if (rideRequestRepository.hasOtherParticipants(requestId)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This ride request cannot be edited after another user has joined");
        }

        return rideRequest;
    }

    @Transactional
    public RideRequest updateOneWay(
            String email, UUID requestId, UpdateRideRequestRequest form) {

        var current = getForEdit(email, requestId);
        if (current.getRoundTripId() != null
                || current.getRideType() == RideType.ROUND_TRIP) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Edit both legs of a round trip together");
        }

        boolean isArrival = current.getRideType() == RideType.ARRIVAL;
        if (isArrival && (form.arrivalTime() == null || form.departureTime() != null)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "An arrival request needs only an arrival time");
        }
        if (!isArrival && (form.departureTime() == null || form.arrivalTime() != null)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A departure request needs only a departure time");
        }

        var city = form.city().trim();
        var street = form.streetAddress().trim();
        var description = form.description() == null ? null : form.description().trim();

        var updated = new RideRequest(
                current.getRideType(),
                isArrival ? null : LocalTime.parse(form.departureTime()),
                current.getRoundTripId(),
                current.getRequestId(),
                current.getUserId(),
                city,
                street,
                isArrival ? LocalTime.parse(form.arrivalTime()) : null,
                EnumSet.copyOf(form.daysOfWeek()),
                description == null || description.isEmpty() ? null : description,
                current.getStatus());

        boolean addressChanged = !city.equals(current.getCity())
                || !street.equals(current.getStreetAddress());
        updated.setLocation(addressChanged
                ? geocoder.locate(street, city)
                : current.getLocation());

        return rideRequestRepository.update(updated)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Ride request not found"));
    }
}