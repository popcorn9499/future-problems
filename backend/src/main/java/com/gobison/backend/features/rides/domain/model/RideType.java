package com.gobison.backend.features.rides.domain.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum RideType {
    @JsonProperty("arriving")
    ARRIVAL,

    @JsonProperty("departing")
    DEPARTURE,

    @JsonProperty("roundTrip")
    ROUND_TRIP
}
