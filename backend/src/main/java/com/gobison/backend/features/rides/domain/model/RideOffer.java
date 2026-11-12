package com.gobison.backend.features.rides.domain.model;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Set;
import java.util.UUID;

public class RideOffer {

    private final RideType rideType;
    private final LocalTime departureTime;
    private final UUID roundTripId;

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
            RideType rideType,
            LocalTime departureTime,
            UUID roundTripId,
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
        this.rideType = rideType;
        this.departureTime = departureTime;
        this.roundTripId = roundTripId;
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
    public RideType getRideType() {
        return rideType;
    }

    public LocalTime getDepartureTime() {
        return departureTime;
    }

    public UUID getRoundTripId() {
        return roundTripId;
    }
}
