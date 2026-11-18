package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

public interface RideRequestRepository {

    RideRequest create(RideRequest rideRequest);

    Optional<RideRequest> findById(UUID requestId);

    List<RideRequest> findRoundTripLegs(UUID roundTripId, String ownerEmail);

    boolean hasOtherParticipants(UUID requestId);

    Optional<RideRequest> update(RideRequest updatedRequest);

    boolean cancelForOwner(String ownerEmail, Set<UUID> requestIds);
}