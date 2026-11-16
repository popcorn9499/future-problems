package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Service
public class ManageRideRequestService {

    private final UserRepository userRepository;
    private final RideRequestRepository rideRequestRepository;

    public ManageRideRequestService(
            UserRepository userRepository,
            RideRequestRepository rideRequestRepository) {
        this.userRepository = userRepository;
        this.rideRequestRepository = rideRequestRepository;
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
}