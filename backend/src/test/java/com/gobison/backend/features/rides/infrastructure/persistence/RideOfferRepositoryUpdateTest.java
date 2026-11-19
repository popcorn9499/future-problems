package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RideOfferRepositoryUpdateTest {

    @Mock private EntityManager entityManager;
    @InjectMocks private RideOfferRepositoryImpl offers;

    private final UUID tripId = UUID.randomUUID();
    private final UUID arrivalId = UUID.randomUUID();
    private final UUID departureId = UUID.randomUUID();

    @Test
    void updatesBothLegsAndKeepsTheirIds() {
        var arrival = leg(arrivalId, RideType.ARRIVAL, 3);
        var departure = leg(departureId, RideType.DEPARTURE, 3);
        var first = new RideOfferEntity(leg(arrivalId, RideType.ARRIVAL, 1));
        var second = new RideOfferEntity(leg(departureId, RideType.DEPARTURE, 1));
        when(entityManager.find(RideOfferEntity.class, arrivalId)).thenReturn(first);
        when(entityManager.find(RideOfferEntity.class, departureId)).thenReturn(second);

        var saved = offers.updateAll(List.of(arrival, departure)).orElseThrow();

        assertEquals(List.of(arrivalId, departureId), saved.stream().map(RideOffer::getOfferId).toList());
        assertEquals(3, first.toDomain().getPassengerNum());
        assertEquals(3, second.toDomain().getPassengerNum());
        verify(entityManager).flush();
    }

    @Test
    void missingSecondLegLeavesFirstLegUntouched() {
        var first = new RideOfferEntity(leg(arrivalId, RideType.ARRIVAL, 1));
        when(entityManager.find(RideOfferEntity.class, arrivalId)).thenReturn(first);

        var saved = offers.updateAll(List.of(
                leg(arrivalId, RideType.ARRIVAL, 3), leg(departureId, RideType.DEPARTURE, 3)));

        assertTrue(saved.isEmpty());
        assertEquals(1, first.toDomain().getPassengerNum());
        verify(entityManager, never()).flush();
    }

    private RideOffer leg(UUID id, RideType type, int seats) {
        return new RideOffer(type, type == RideType.DEPARTURE ? LocalTime.of(17, 0) : null,
                tripId, id, "owner@myumanitoba.ca", "Winnipeg", "123 Main Street",
                type == RideType.ARRIVAL ? LocalTime.of(8, 0) : null, Set.of(DayOfWeek.MONDAY),
                null, "OPEN", seats, false);
    }
}
