package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

public interface RideRequestRepository {
    void cancelOpenForOwner(String ownerEmail);

    enum ManagementConflict {
        CHANGED, CANCELLED, PARTLY_CANCELLED
    }

    Optional<ManagementConflict> lockForManagement(String ownerEmail, Set<UUID> ids);

    RideRequest create(RideRequest rideRequest);

    Optional<RideRequest> findById(UUID requestId);

    List<RideRequest> findRoundTripLegs(UUID roundTripId, String ownerEmail);

    boolean hasOtherParticipants(UUID requestId);

    Optional<RideRequest> update(RideRequest updatedRequest);

    boolean cancelForOwner(String ownerEmail, Set<UUID> requestIds);

    List<RideRequest> findFiltered(
            String excludeUserEmail,
            String city,
            List<DayOfWeek> daysOfWeek,
            RideType rideType,
            LocalTime departureTime,
            LocalTime arrivalTime,
            String status
    );
}
