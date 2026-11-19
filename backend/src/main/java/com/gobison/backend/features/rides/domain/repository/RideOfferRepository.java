package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;

public interface RideOfferRepository {
    RideOffer create(RideOffer rideOffer);

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