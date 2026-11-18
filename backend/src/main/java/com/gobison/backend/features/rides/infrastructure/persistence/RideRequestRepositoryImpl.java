package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.*;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class RideRequestRepositoryImpl implements RideRequestRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional
    public RideRequest create(RideRequest rideRequest) {
        var entity = new RideRequestEntity(rideRequest);
        entityManager.persist(entity);
        entityManager.flush();
        return entity.toDomain();
    }

    @Override
    @Transactional(readOnly = true)
    public List<RideRequest> findFiltered(
            String excludeUserEmail,
            String city,
            List<DayOfWeek> daysOfWeek,
            RideType rideType,
            LocalTime departureTime,
            LocalTime arrivalTime,
            String status) {

        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<RideRequestEntity> query = cb.createQuery(RideRequestEntity.class);
        Root<RideRequestEntity> root = query.from(RideRequestEntity.class);

        List<Predicate> predicates = new ArrayList<>();

        // Rule: Users must not receive their own ride requests
        if (excludeUserEmail != null) {
            predicates.add(cb.notEqual(root.get("userEmail"), excludeUserEmail));
        }

        // Filter by status (defaults to OPEN if null)
        if (status != null && !status.isBlank()) {
            predicates.add(cb.equal(root.get("status"), status));
        }

        // Optional city filter
        if (city != null && !city.isBlank()) {
            predicates.add(cb.equal(cb.lower(root.get("city")), city.trim().toLowerCase()));
        }

        // Optional rideType filter
        if (rideType != null) {
            predicates.add(cb.equal(root.get("rideType"), rideType));
        }

        // Optional daysOfWeek filter (Ensures entity contains ALL requested days)
        if (daysOfWeek != null && !daysOfWeek.isEmpty()) {
            Subquery<Long> subquery = query.subquery(Long.class);
            Root<RideRequestEntity> subRoot = subquery.from(RideRequestEntity.class);
            Join<RideRequestEntity, DayOfWeek> subDays = subRoot.join("daysOfWeek");
            
            subquery.select(cb.count(subDays))
                    .where(
                        cb.equal(subRoot.get("id"), root.get("id")),
                        subDays.in(daysOfWeek)
                    );

            predicates.add(cb.equal(subquery, (long) daysOfWeek.size()));
        }

        // Optional departureTime filter
        if (departureTime != null) {
            predicates.add(cb.equal(root.get("departureTime"), departureTime));
        }

        // Optional arrivalTime filter
        if (arrivalTime != null) {
            predicates.add(cb.equal(root.get("arrivalTime"), arrivalTime));
        }

        query.where(predicates.toArray(new Predicate[0]));

        return entityManager.createQuery(query)
                .getResultList()
                .stream()
                .map(RideRequestEntity::toDomain)
                .toList();
    }
}