package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.domain.model.GeoLocation;
import jakarta.validation.constraints.AssertTrue;

public interface RidePickupInput {
    String streetAddress();

    Point location();

    @AssertTrue(message = "Enter a street address or choose a pickup point")
    default boolean isPickupProvided() {
        return location() != null || (streetAddress() != null && !streetAddress().isBlank());
    }

    default String pickupLabel() {
        return streetAddress() == null || streetAddress().isBlank()
                ? "Pinned pickup" : streetAddress().trim();
    }

    record Point(Double latitude, Double longitude) {
        public Point {
            if (latitude == null || longitude == null) {
                throw new IllegalArgumentException("Both pickup coordinates are required");
            }
            new GeoLocation(longitude, latitude);
        }

        public GeoLocation toLocation() {
            return new GeoLocation(longitude, latitude);
        }
    }
}
