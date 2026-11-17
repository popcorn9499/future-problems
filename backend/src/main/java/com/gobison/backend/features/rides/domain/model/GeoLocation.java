package com.gobison.backend.features.rides.domain.model;

public record GeoLocation(double longitude, double latitude) {
    public GeoLocation {
        if (!Double.isFinite(longitude) || !Double.isFinite(latitude)
                || Math.abs(longitude) > 180 || Math.abs(latitude) > 90) {
            throw new IllegalArgumentException("Invalid coordinates");
        }
    }
}
