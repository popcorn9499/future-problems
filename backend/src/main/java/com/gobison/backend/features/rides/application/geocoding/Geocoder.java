package com.gobison.backend.features.rides.application.geocoding;

import com.gobison.backend.features.rides.domain.model.GeoLocation;

public interface Geocoder {
    GeoLocation locate(String street, String city);
}
