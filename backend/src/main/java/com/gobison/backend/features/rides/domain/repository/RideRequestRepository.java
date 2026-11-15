package com.gobison.backend.features.rides.domain.repository;

import com.gobison.backend.features.rides.domain.model.RideRequest;

public interface RideRequestRepository {

    RideRequest create(RideRequest rideRequest);
}
