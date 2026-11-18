package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.model.GeoLocation;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
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
@Table(name = "ride_requests")
public class RideRequestEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "ride_type", nullable = false, length = 9)
    private RideType rideType;

    @Column(name = "departure_time")
    private LocalTime departureTime;

    @Column(name = "round_trip_id")
    private UUID roundTripId;

    @JdbcTypeCode(SqlTypes.GEOGRAPHY)
    @Column(name = "location", columnDefinition = "geography(Point,4326)")
    private Point location;

    @Id
    @Column(name = "request_id", nullable = false)
    private UUID id;

    @Column(name = "user_email", nullable = false)
    private String userEmail;

    @Column(nullable = false)
    private String city;

    @Column(name = "street_address", nullable = false)
    private String streetAddress;

    @Column(name = "arrival_time")
    private LocalTime arrivalTime;

    @Column(columnDefinition = "text")
    private String description;

    @Column(nullable = false, length = 20)
    private String status;

    @ElementCollection
    @CollectionTable(name = "ride_request_days", joinColumns = @JoinColumn(name = "request_id"), uniqueConstraints = @UniqueConstraint(columnNames = {
            "request_id", "day_of_week" }))
    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 9)
    private Set<DayOfWeek> daysOfWeek;

    protected RideRequestEntity() {
    }

    public RideRequestEntity(RideRequest rideRequest) {
        id = rideRequest.getRequestId();
        userEmail = rideRequest.getUserId();
        rideType = rideRequest.getRideType();
        roundTripId = rideRequest.getRoundTripId();
        status = rideRequest.getStatus();
        daysOfWeek = EnumSet.noneOf(DayOfWeek.class);

        updateDetails(rideRequest);
    }

    void updateDetails(RideRequest rideRequest) {
        city = rideRequest.getCity();
        streetAddress = rideRequest.getStreetAddress();
        arrivalTime = rideRequest.getArrivalTime();
        departureTime = rideRequest.getDepartureTime();
        description = rideRequest.getDescription();

        daysOfWeek.clear();
        daysOfWeek.addAll(rideRequest.getDaysOfWeek());

        var coordinates = rideRequest.getLocation();
        location = coordinates == null
                ? null
                : new GeometryFactory(new PrecisionModel(), 4326)
                        .createPoint(new Coordinate(
                                coordinates.longitude(),
                                coordinates.latitude()));
    }

    void cancel() {
        status = "CANCELLED";
    }

    public RideRequest toDomain() {
        var ride = new RideRequest(
                rideType,
                departureTime,
                roundTripId,
                id,
                userEmail,
                city,
                streetAddress,
                arrivalTime,
                EnumSet.copyOf(daysOfWeek),
                description,
                status);
        if (location != null)
            ride.setLocation(new GeoLocation(location.getX(), location.getY()));
        return ride;
    }
}