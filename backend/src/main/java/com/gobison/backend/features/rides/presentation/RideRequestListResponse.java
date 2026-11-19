package com.gobison.backend.features.rides.presentation;

import java.util.List;

public record RideRequestListResponse(List<RideRequestResponse> requests) {
    public static RideRequestListResponse of(List<RideRequestResponse> requests) {
        return new RideRequestListResponse(requests);
    }
}
