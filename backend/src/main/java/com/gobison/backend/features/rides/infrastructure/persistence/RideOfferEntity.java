package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "ride_offers")
public class RideOfferEntity {

    @Id
    @Column(name = "offer_id", nullable = false)
    private UUID id;

    @Column(name = "user_email", nullable = false)
    private String userEmail;

    @Column(nullable = false)
    private String city;

    @Column(name = "street_address", nullable = false)
    private String streetAddress;

    @Column(name = "arrival_time", nullable = false)
    private LocalTime arrivalTime;

    @Column(columnDefinition = "text")
    private String description;

    @Column(nullable = false, length = 20)
    private String status;

    @ElementCollection
    @CollectionTable(
            name = "ride_offer_days",
            joinColumns = @JoinColumn(name = "offer_id"),
            uniqueConstraints = @UniqueConstraint(columnNames = {"offer_id", "day_of_week"}))
    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 9)
    private Set<DayOfWeek> daysOfWeek;

    @Column(name = "passenger_num", nullable = false)
    private int passengerNum;

    @Column(name = "asking_for_drivers", nullable = false)
    private boolean askingForDrivers;

    protected RideOfferEntity() {
    }

    public RideOfferEntity(RideOffer rideOffer) {
        id = rideOffer.getOfferId();
        userEmail = rideOffer.getUserId();
        city = rideOffer.getCity();
        streetAddress = rideOffer.getStreetAddress();
        arrivalTime = rideOffer.getArrivalTime();
        description = rideOffer.getDescription();
        status = rideOffer.getStatus();
        daysOfWeek = EnumSet.copyOf(rideOffer.getDaysOfWeek());
        passengerNum = rideOffer.getPassengerNum();
        askingForDrivers = rideOffer.isAskingForDrivers();
    }

    public RideOffer toDomain() {
        return new RideOffer(
                id,
                userEmail,
                city,
                streetAddress,
                arrivalTime,
                EnumSet.copyOf(daysOfWeek),
                description,
                status,
                passengerNum,
                askingForDrivers);
    }
}
