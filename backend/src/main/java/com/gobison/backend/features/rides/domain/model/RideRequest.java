package com.gobison.backend.features.rides.domain.model;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Set;
import java.util.UUID;

public class RideRequest {

    private final UUID requestId;
    private final String userId;
    private final String city;
    private final String streetAddress;
    private final LocalTime arrivalTime;
    private final Set<DayOfWeek> daysOfWeek;
    private final String description;
    private final String status;

    public RideRequest(
            UUID requestId,
            String userId,
            String city,
            String streetAddress,
            LocalTime arrivalTime,
            Set<DayOfWeek> daysOfWeek,
            String description,
            String status) {
        this.requestId = requestId;
        this.userId = userId;
        this.city = city;
        this.streetAddress = streetAddress;
        this.arrivalTime = arrivalTime;
        this.daysOfWeek = daysOfWeek;
        this.description = description;
        this.status = status;
    }

    public UUID getRequestId() {
        return requestId;
    }

    public String getUserId() {
        return userId;
    }

    public String getCity() {
        return city;
    }

    public String getStreetAddress() {
        return streetAddress;
    }

    public LocalTime getArrivalTime() {
        return arrivalTime;
    }

    public Set<DayOfWeek> getDaysOfWeek() {
        return daysOfWeek;
    }

    public String getDescription() {
        return description;
    }

    public String getStatus() {
        return status;
    }
}
