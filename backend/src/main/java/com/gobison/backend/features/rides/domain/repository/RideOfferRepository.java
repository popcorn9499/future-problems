package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RideOfferRepository {

    enum CancellationResult {
        CANCELLED, CONFIRMATION_REQUIRED, OFFER_CHANGED
    }

    RideOffer create(RideOffer rideOffer);

    Optional<RideOffer> findById(UUID offerId);

    List<RideOffer> findRoundTripLegs(UUID roundTripId, String ownerEmail);

    Optional<List<RideOffer>> updateIfEditable(String ownerEmail, List<RideOffer> editedLegs);

    CancellationResult cancelForOwner(String ownerEmail, List<UUID> offerIds, boolean confirmParticipants);

    List<RideOffer> findFilteredOffers(
            String userEmail,
            String city,
            List<DayOfWeek> daysOfWeek,
            RideType rideType,
            Boolean isRoundTrip,
            LocalTime departureTime,
            LocalTime arrivalTime,
            String status
    );
}