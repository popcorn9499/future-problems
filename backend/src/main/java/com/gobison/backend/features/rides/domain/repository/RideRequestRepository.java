package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;

public interface RideRequestRepository {
    RideRequest create(RideRequest rideRequest);

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