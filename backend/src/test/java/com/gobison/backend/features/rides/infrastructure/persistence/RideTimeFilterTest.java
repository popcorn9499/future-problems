package com.gobison.backend.features.rides.infrastructure.persistence;

import jakarta.persistence.EntityManager;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Path;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalTime;
import java.util.List;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RideTimeFilterTest {
    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
    private EntityManager entityManager;
    @Mock private CriteriaBuilder builder;
    @Mock private CriteriaQuery<RideRequestEntity> criteria;
    @Mock private Root<RideRequestEntity> requestRoot;
    @Mock private Path<LocalTime> departureField;
    @Mock private Path<LocalTime> arrivalField;
    @Mock private Predicate afterStart;
    @Mock private Predicate beforeEnd;
    @Mock private Predicate departureRange;
    @Mock private Predicate arrivalRange;
    @InjectMocks private RideRequestRepositoryImpl requests;
    @InjectMocks private RideOfferRepositoryImpl offers;

    @Test
    void requestsUseInclusiveBoundsAndWrapAtMidnight() {
        when(entityManager.getCriteriaBuilder()).thenReturn(builder);
        when(builder.createQuery(RideRequestEntity.class)).thenReturn(criteria);
        when(criteria.from(RideRequestEntity.class)).thenReturn(requestRoot);
        when(requestRoot.<LocalTime>get("departureTime")).thenReturn(departureField);
        when(requestRoot.<LocalTime>get("arrivalTime")).thenReturn(arrivalField);
        when(builder.greaterThanOrEqualTo(departureField, LocalTime.of(23, 15)))
                .thenReturn(afterStart);
        when(builder.lessThanOrEqualTo(departureField, LocalTime.of(0, 15)))
                .thenReturn(beforeEnd);
        when(builder.or(afterStart, beforeEnd)).thenReturn(departureRange);
        when(builder.between(arrivalField, LocalTime.of(8, 0), LocalTime.of(9, 0)))
                .thenReturn(arrivalRange);
        when(entityManager.createQuery(criteria).getResultList()).thenReturn(List.of());

        requests.findFiltered(null, null, List.of(), null,
                LocalTime.of(23, 45), LocalTime.of(8, 30), null);

        verify(criteria).where(departureRange, arrivalRange);
    }

    @Test
    void offersUseInclusiveBoundsAndWrapAtMidnight() {
        var offerQuery = entityManager.createQuery(
                "SELECT e FROM RideOfferEntity e WHERE e.userEmail != :userEmail"
                        + " AND e.status = :status"
                        + " AND e.departureTime BETWEEN :departureTimeStart AND :departureTimeEnd"
                        + " AND (e.arrivalTime >= :arrivalTimeStart OR e.arrivalTime <= :arrivalTimeEnd)",
                RideOfferEntity.class);
        when(offerQuery.getResultList()).thenReturn(List.of());

        offers.findFilteredOffers("viewer@example.com", null, List.of(), null, null,
                LocalTime.of(16, 30), LocalTime.of(0, 10), "OPEN");

        verify(offerQuery).setParameter("departureTimeStart", LocalTime.of(16, 0));
        verify(offerQuery).setParameter("departureTimeEnd", LocalTime.of(17, 0));
        verify(offerQuery).setParameter("arrivalTimeStart", LocalTime.of(23, 40));
        verify(offerQuery).setParameter("arrivalTimeEnd", LocalTime.of(0, 40));
    }
}
