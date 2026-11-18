package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.application.geocoding.Geocoder;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.rides.presentation.UpdateRideRequestRequest;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ManageRideRequestService {

    public enum CancellationResult {
        CANCELLED,
        CONFIRMATION_REQUIRED
    }

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

        requireEditable(List.of(rideRequest), requestId);
        return rideRequest;
    }

    private void requireEditable(List<RideRequest> legs, UUID requestId) {
        if (legs.stream().anyMatch(this::isCancelled)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Cancelled ride requests cannot be edited");
        }
        if (rideRequestRepository.hasOtherParticipants(requestId)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This ride request cannot be edited after another user has joined");
        }
    }

    private boolean isCancelled(RideRequest ride) {
        return "CANCELLED".equals(ride.getStatus());
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

        var arrivalTime = isArrival ? LocalTime.parse(form.arrivalTime()) : null;
        var departureTime = isArrival ? null : LocalTime.parse(form.departureTime());
        return saveEditedLegs(List.of(current), form, arrivalTime, departureTime).getFirst();
    }

    @Transactional
    public List<RideRequest> updateRoundTrip(
            String email, UUID requestId, UpdateRideRequestRequest form) {
        var current = getForOwner(email, requestId);
        var legs = getRoundTripLegs(current);
        requireEditable(legs, requestId);

        if (form.arrivalTime() == null || form.departureTime() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A round trip needs both arrival and departure times");
        }
        var arrivalTime = LocalTime.parse(form.arrivalTime());
        var departureTime = LocalTime.parse(form.departureTime());
        if (!departureTime.isAfter(arrivalTime)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "departureTime must be later than arrivalTime");
        }

        return saveEditedLegs(legs, form, arrivalTime, departureTime);
    }

    @Transactional
    public CancellationResult cancel(String email, UUID requestId, boolean confirmParticipants) {
        var current = getForOwner(email, requestId);
        boolean oneWay = current.getRoundTripId() == null && current.getRideType() != RideType.ROUND_TRIP;
        var legs = oneWay ? List.of(current) : getRoundTripLegs(current);

        if (legs.stream().allMatch(this::isCancelled)) {
            return CancellationResult.CANCELLED;
        }
        if (!confirmParticipants && rideRequestRepository.hasOtherParticipants(requestId)) {
            return CancellationResult.CONFIRMATION_REQUIRED;
        }

        Set<UUID> ids = legs.stream().map(RideRequest::getRequestId).collect(Collectors.toSet());
        if (!rideRequestRepository.cancelForOwner(current.getUserId(), ids)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "The ride request changed before it could be cancelled");
        }
        return CancellationResult.CANCELLED;
    }

    private List<RideRequest> getRoundTripLegs(RideRequest current) {
        if (current.getRoundTripId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "This request is not part of a round trip");
        }

        var legs = rideRequestRepository.findRoundTripLegs(
                current.getRoundTripId(), current.getUserId());
        if (legs.size() != 2 || legs.stream().noneMatch(leg -> current.getRequestId().equals(leg.getRequestId()))) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "The round trip does not have a complete pair of requests");
        }
        var arrival = legOfType(legs, RideType.ARRIVAL);
        var departure = legOfType(legs, RideType.DEPARTURE);
        return List.of(arrival, departure);
    }

    private RideRequest legOfType(List<RideRequest> legs, RideType type) {
        return legs.stream()
                .filter(leg -> leg.getRideType() == type)
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.CONFLICT, "The round trip needs one arrival and one departure"));
    }

    private List<RideRequest> saveEditedLegs(
            List<RideRequest> legs, UpdateRideRequestRequest form,
            LocalTime arrivalTime, LocalTime departureTime) {
        var city = form.city().trim();
        var street = form.streetAddress().trim();
        var description = form.description() == null ? null : form.description().trim();
        boolean addressChanged = legs.stream().anyMatch(
                leg -> !city.equals(leg.getCity()) || !street.equals(leg.getStreetAddress()));
        var newLocation = addressChanged ? geocoder.locate(street, city) : null;

        List<RideRequest> saved = new ArrayList<>(legs.size());
        for (var leg : legs) {
            boolean isArrival = leg.getRideType() == RideType.ARRIVAL;
            var updated = new RideRequest(
                    leg.getRideType(),
                    isArrival ? null : departureTime,
                    leg.getRoundTripId(),
                    leg.getRequestId(),
                    leg.getUserId(),
                    city,
                    street,
                    isArrival ? arrivalTime : null,
                    EnumSet.copyOf(form.daysOfWeek()),
                    description == null || description.isEmpty() ? null : description,
                    leg.getStatus());
            updated.setLocation(addressChanged ? newLocation : leg.getLocation());
            var result = rideRequestRepository.update(updated)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Ride request not found"));
            saved.add(result);
        }
        return saved;
    }
}