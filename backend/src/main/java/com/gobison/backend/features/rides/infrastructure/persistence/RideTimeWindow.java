package com.gobison.backend.features.rides.infrastructure.persistence;

import java.time.LocalTime;

record RideTimeWindow(LocalTime start, LocalTime end) {
    static RideTimeWindow around(LocalTime time) {
        return new RideTimeWindow(time.minusMinutes(30), time.plusMinutes(30));
    }

    boolean crossesMidnight() {
        return start.isAfter(end);
    }
}
