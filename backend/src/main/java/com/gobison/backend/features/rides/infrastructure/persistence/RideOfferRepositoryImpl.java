package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;

@Repository
public class RideOfferRepositoryImpl implements RideOfferRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional
    public RideOffer create(RideOffer rideOffer) {
        var entity = new RideOfferEntity(rideOffer);
        entityManager.persist(entity);
        entityManager.flush();
        return entity.toDomain();
    }

    @Override
    @Transactional(readOnly = true)
    public List<RideOffer> findFilteredOffers(
            String userEmail,
            String city,
            List<DayOfWeek> daysOfWeek,
            RideType rideType,
            Boolean isRoundTrip,
            LocalTime departureTime,
            LocalTime arrivalTime,
            String status) {

        StringBuilder jpql = new StringBuilder("SELECT e FROM RideOfferEntity e WHERE e.userEmail != :userEmail");

        if (status != null && !status.isBlank()) {
            jpql.append(" AND e.status = :status");
        }
        if (city != null && !city.isBlank()) {
            jpql.append(" AND LOWER(e.city) = LOWER(:city)");
        }
        if (rideType != null) {
            jpql.append(" AND e.rideType = :rideType");
        }
        if (isRoundTrip != null) {
            if (isRoundTrip) {
                jpql.append(" AND e.roundTripId IS NOT NULL");
            } else {
                jpql.append(" AND e.roundTripId IS NULL");
            }
        }
        if (departureTime != null) {
            jpql.append(" AND e.departureTime = :departureTime");
        }
        if (arrivalTime != null) {
            jpql.append(" AND e.arrivalTime = :arrivalTime");
        }
        if (daysOfWeek != null && !daysOfWeek.isEmpty()) {
            jpql.append(" AND (SELECT COUNT(d) FROM e.daysOfWeek d WHERE d IN :daysOfWeek) = :dayCount");
        }

        var query = entityManager.createQuery(jpql.toString(), RideOfferEntity.class);
        query.setParameter("userEmail", userEmail);

        if (status != null && !status.isBlank()) {
            query.setParameter("status", status.trim());
        }
        if (city != null && !city.isBlank()) {
            query.setParameter("city", city.trim());
        }
        if (rideType != null) {
            query.setParameter("rideType", rideType);
        }
        if (departureTime != null) {
            query.setParameter("departureTime", departureTime);
        }
        if (arrivalTime != null) {
            query.setParameter("arrivalTime", arrivalTime);
        }
        if (daysOfWeek != null && !daysOfWeek.isEmpty()) {
            query.setParameter("daysOfWeek", daysOfWeek);
            query.setParameter("dayCount", (long) daysOfWeek.size());
        }

        return query.getResultList().stream()
                .map(RideOfferEntity::toDomain)
                .toList();
    }
}