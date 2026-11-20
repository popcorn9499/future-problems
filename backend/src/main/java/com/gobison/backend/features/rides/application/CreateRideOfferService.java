package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;

import com.gobison.backend.features.rides.presentation.CreateRideOfferRequest;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import com.gobison.backend.features.rides.application.geocoding.Geocoder;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.EnumSet;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class CreateRideOfferService {

    private final Geocoder geocoder;
    private final RideWriter writer;
    private final UserRepository userRepository;

    public CreateRideOfferService(
            UserRepository userRepository,
            Geocoder geocoder, RideWriter writer) {
        this.geocoder = geocoder;
        this.writer = writer;
        this.userRepository = userRepository;
    }

    public List<RideOffer> create(String email, CreateRideOfferRequest request) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        if (!user.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }

        var description = request.description() == null ? null : request.description().trim();
        if (description != null && description.isEmpty()) {
            description = null;
        }

        if (request.rideType() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "rideType is required");
        }

        boolean includesArrival = request.rideType() != RideType.DEPARTURE;
        boolean includesDeparture = request.rideType() != RideType.ARRIVAL;

        if (includesArrival && request.arrivalTime() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "arrivalTime is required");
        }
        if (includesDeparture && request.departureTime() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "departureTime is required");
        }

        var arrivalTime = request.arrivalTime() == null ? null : LocalTime.parse(request.arrivalTime());
        var departureTime = request.departureTime() == null ? null : LocalTime.parse(request.departureTime());
        boolean roundTrip = request.rideType() == RideType.ROUND_TRIP;

        if (roundTrip && !departureTime.isAfter(arrivalTime)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "departureTime must be later than arrivalTime");
        }

        RideDays.validate(request.daysOfWeek(), List.of());
        var location = geocoder.locate(request.streetAddress().trim(), request.city().trim());

        UUID roundTripId = roundTrip ? UUID.randomUUID() : null;
        List<RideOffer> createdRides = new ArrayList<>();

        if (includesArrival) {
            createdRides.add(new RideOffer(
                    RideType.ARRIVAL,
                    null,
                    roundTripId,
                    UUID.randomUUID(),
                    user.getEmail(),
                    request.city().trim(),
                    request.streetAddress().trim(),
                    arrivalTime,
                    EnumSet.copyOf(request.daysOfWeek()),
                    description,
                    "OPEN",
                    request.passengerNum(),
                    Boolean.TRUE.equals(request.askingForDrivers())));
        }

        if (includesDeparture) {
            createdRides.add(new RideOffer(
                    RideType.DEPARTURE,
                    departureTime,
                    roundTripId,
                    UUID.randomUUID(),
                    user.getEmail(),
                    request.city().trim(),
                    request.streetAddress().trim(),
                    null,
                    EnumSet.copyOf(request.daysOfWeek()),
                    description,
                    "OPEN",
                    request.passengerNum(),
                    Boolean.TRUE.equals(request.askingForDrivers())));
        }

        createdRides.forEach(ride -> ride.setLocation(location));
        return writer.saveOffers(createdRides);
    }
}
