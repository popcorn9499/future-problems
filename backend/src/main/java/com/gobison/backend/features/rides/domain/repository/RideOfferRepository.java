package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideOffer;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RideOfferRepository {

    RideOffer create(RideOffer rideOffer);

    Optional<RideOffer> findById(UUID offerId);

    List<RideOffer> findRoundTripLegs(UUID roundTripId, String ownerEmail);
}
