package com.gobison.backend.features.rides.presentation;

import java.util.List;

public record RideOfferListResponse(List<RideOfferResponse> offers) {
    public static RideOfferListResponse of(List<RideOfferResponse> offers) {
        return new RideOfferListResponse(offers);
    }
}