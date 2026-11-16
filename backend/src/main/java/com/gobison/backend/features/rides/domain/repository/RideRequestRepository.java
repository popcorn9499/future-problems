package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideRequest;

import java.util.Optional;
import java.util.UUID;

public interface RideRequestRepository {

    RideRequest create(RideRequest rideRequest);

    Optional<RideRequest> findById(UUID requestId);
}