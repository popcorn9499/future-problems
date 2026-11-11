package com.gobison.backend.features.rides.domain.model;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Set;
import java.util.UUID;

public class RideOffer {

    private final UUID offerId;
    private final String userId;
    private final String city;
    private final String streetAddress;
    private final LocalTime arrivalTime;
    private final Set<DayOfWeek> daysOfWeek;
    private final String description;
    private final String status;
    private final int passengerNum;
    private final boolean askingForDrivers;

    public RideOffer(
            UUID offerId,
            String userId,
            String city,
            String streetAddress,
            LocalTime arrivalTime,
            Set<DayOfWeek> daysOfWeek,
            String description,
            String status,
            int passengerNum,
            boolean askingForDrivers) {
        this.offerId = offerId;
        this.userId = userId;
        this.city = city;
        this.streetAddress = streetAddress;
        this.arrivalTime = arrivalTime;
        this.daysOfWeek = daysOfWeek;
        this.description = description;
        this.status = status;
        this.passengerNum = passengerNum;
        this.askingForDrivers = askingForDrivers;
    }

    public UUID getOfferId() {
        return offerId;
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

    public int getPassengerNum() {
        return passengerNum;
    }

    public boolean isAskingForDrivers() {
        return askingForDrivers;
    }
}
