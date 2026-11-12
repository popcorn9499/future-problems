package com.gobison.backend.features.rides;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.infrastructure.persistence.RideOfferEntity;
import com.gobison.backend.features.rides.infrastructure.persistence.RideRequestEntity;
import org.junit.jupiter.api.Test;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.EnumSet;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;

class RideEntityMappingTest {

    @Test
    void preservesRequestLegFieldsThroughEntityMapping() {
        for (RideType direction : new RideType[] {RideType.ARRIVAL, RideType.DEPARTURE}) {
            UUID requestId = UUID.randomUUID();
            UUID roundTripId = UUID.randomUUID();
            LocalTime arrivalTime = direction == RideType.ARRIVAL ? LocalTime.of(8, 30) : null;
            LocalTime departureTime = direction == RideType.DEPARTURE ? LocalTime.of(16, 30) : null;
            var days = EnumSet.of(DayOfWeek.MONDAY, DayOfWeek.FRIDAY);
            var request = new RideRequest(
                    direction, departureTime, roundTripId, requestId, "ada@myumanitoba.ca",
                    "Winnipeg", "123 Main", arrivalTime, days, "Ride home", "OPEN");

            var restored = new RideRequestEntity(request).toDomain();

            assertAll(
                    () -> assertEquals(direction, restored.getRideType()),
                    () -> assertEquals(requestId, restored.getRequestId()),
                    () -> assertEquals(roundTripId, restored.getRoundTripId()),
                    () -> assertEquals(arrivalTime, restored.getArrivalTime()),
                    () -> assertEquals(departureTime, restored.getDepartureTime()),
                    () -> assertEquals(days, restored.getDaysOfWeek()),
                    () -> assertEquals(request.getUserId(), restored.getUserId()),
                    () -> assertEquals(request.getCity(), restored.getCity()),
                    () -> assertEquals(request.getStreetAddress(), restored.getStreetAddress()),
                    () -> assertEquals(request.getDescription(), restored.getDescription()),
                    () -> assertEquals("OPEN", restored.getStatus()));
        }
    }

    @Test
    void preservesOfferLegFieldsThroughEntityMapping() {
        for (RideType direction : new RideType[] {RideType.ARRIVAL, RideType.DEPARTURE}) {
            UUID offerId = UUID.randomUUID();
            LocalTime arrivalTime = direction == RideType.ARRIVAL ? LocalTime.of(8, 30) : null;
            LocalTime departureTime = direction == RideType.DEPARTURE ? LocalTime.of(16, 30) : null;
            var days = EnumSet.of(DayOfWeek.WEDNESDAY);
            var offer = new RideOffer(
                    direction, departureTime, null, offerId, "ada@myumanitoba.ca",
                    "Winnipeg", "123 Main", arrivalTime, days, null, "OPEN", 3, true);

            var restored = new RideOfferEntity(offer).toDomain();

            assertAll(
                    () -> assertEquals(direction, restored.getRideType()),
                    () -> assertEquals(offerId, restored.getOfferId()),
                    () -> assertEquals(null, restored.getRoundTripId()),
                    () -> assertEquals(arrivalTime, restored.getArrivalTime()),
                    () -> assertEquals(departureTime, restored.getDepartureTime()),
                    () -> assertEquals(days, restored.getDaysOfWeek()),
                    () -> assertEquals(offer.getUserId(), restored.getUserId()),
                    () -> assertEquals(offer.getCity(), restored.getCity()),
                    () -> assertEquals(offer.getStreetAddress(), restored.getStreetAddress()),
                    () -> assertEquals(offer.getDescription(), restored.getDescription()),
                    () -> assertEquals("OPEN", restored.getStatus()),
                    () -> assertEquals(3, restored.getPassengerNum()),
                    () -> assertEquals(true, restored.isAskingForDrivers()));
        }
    }
}
