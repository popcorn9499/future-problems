package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.rides.presentation.CreateRideRequestRequest;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.EnumSet;
import java.util.UUID;

@Service
public class CreateRideRequestService {

    private final UserRepository userRepository;
    private final RideRequestRepository rideRequestRepository;

    public CreateRideRequestService(
            UserRepository userRepository,
            RideRequestRepository rideRequestRepository) {
        this.userRepository = userRepository;
        this.rideRequestRepository = rideRequestRepository;
    }

    @Transactional
    public RideRequest create(String email, CreateRideRequestRequest request) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        if (!user.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }

        var description = request.description() == null ? null : request.description().trim();
        if (description != null && description.isEmpty()) {
            description = null;
        }

        return rideRequestRepository.create(new RideRequest(
                UUID.randomUUID(),
                user.getEmail(),
                request.city().trim(),
                request.streetAddress().trim(),
                LocalTime.parse(request.arrivalTime()),
                EnumSet.copyOf(request.daysOfWeek()),
                description,
                "OPEN"));
    }
}
