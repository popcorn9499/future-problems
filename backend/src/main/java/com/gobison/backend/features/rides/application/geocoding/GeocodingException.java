package com.gobison.backend.features.rides.application.geocoding;

public class GeocodingException extends RuntimeException {
    private final boolean invalidAddress;

    public GeocodingException(boolean invalidAddress) {
        super(invalidAddress
                ? "We couldn’t locate that address in Canada. Check the street address and city and try again."
                : "Address lookup is temporarily unavailable. Please try again.");
        this.invalidAddress = invalidAddress;
    }

    public boolean isInvalidAddress() { return invalidAddress; }
    public String getCode() { return invalidAddress ? "INVALID_ADDRESS" : "GEOCODING_UNAVAILABLE"; }
}
