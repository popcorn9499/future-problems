package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.presentation.CreateRideOfferRequest;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.EnumSet;
import java.util.UUID;

@Service
public class CreateRideOfferService {

    private final UserRepository userRepository;
    private final RideOfferRepository rideOfferRepository;

    public CreateRideOfferService(
            UserRepository userRepository,
            RideOfferRepository rideOfferRepository) {
        this.userRepository = userRepository;
        this.rideOfferRepository = rideOfferRepository;
    }

    @Transactional
    public RideOffer create(String email, CreateRideOfferRequest request) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        if (!user.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }

        var description = request.description() == null ? null : request.description().trim();
        if (description != null && description.isEmpty()) {
            description = null;
        }

        return rideOfferRepository.create(new RideOffer(
                UUID.randomUUID(),
                user.getEmail(),
                request.city().trim(),
                request.streetAddress().trim(),
                LocalTime.parse(request.arrivalTime()),
                EnumSet.copyOf(request.daysOfWeek()),
                description,
                "OPEN",
                request.passengerNum(),
                Boolean.TRUE.equals(request.askingForDrivers())));
    }
}
