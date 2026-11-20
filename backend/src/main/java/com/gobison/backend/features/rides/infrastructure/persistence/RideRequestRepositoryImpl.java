package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.criteria.*;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

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
    public Optional<RideRequest> findById(UUID requestId) {
        var entity = entityManager.find(RideRequestEntity.class, requestId);
        return Optional.ofNullable(entity).map(RideRequestEntity::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public List<RideRequest> findRoundTripLegs(UUID roundTripId, String ownerEmail) {
        return entityManager.createQuery("""
                select ride from RideRequestEntity ride
                where ride.roundTripId = :roundTripId
                  and ride.userEmail = :ownerEmail
                """, RideRequestEntity.class)
                .setParameter("roundTripId", roundTripId)
                .setParameter("ownerEmail", ownerEmail)
                .getResultList()
                .stream()
                .map(RideRequestEntity::toDomain)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public boolean hasOtherParticipants(UUID requestId) {
        String sql = """
                SELECT EXISTS (
                    SELECT 1
                    FROM ride_requests target
                    JOIN ride_requests leg
                      ON leg.request_id = target.request_id
                      OR leg.round_trip_id = target.round_trip_id
                    JOIN ride_agreements agreement
                      ON agreement.request_id = leg.request_id
                    JOIN ride_agreement_members member
                      ON member.agreement_id = agreement.agreement_id
                    WHERE target.request_id = ?1
                      AND member.user_email <> target.user_email
                )
                """;

        return (Boolean) entityManager.createNativeQuery(sql)
                .setParameter(1, requestId)
                .getSingleResult();
    }

    @Override
    @Transactional(propagation = Propagation.MANDATORY)
    public Optional<ManagementConflict> lockForManagement(String ownerEmail, Set<UUID> ids) {
        if (ids.isEmpty() || ids.size() > 2) {
            return Optional.of(ManagementConflict.CHANGED);
        }
        List<?> statuses = entityManager.createNativeQuery("""
                SELECT status FROM ride_requests
                WHERE user_email = :owner AND request_id IN (:ids)
                ORDER BY request_id FOR UPDATE
                """).setParameter("owner", ownerEmail).setParameter("ids", ids).getResultList();
        if (statuses.size() != ids.size()) {
            return Optional.of(ManagementConflict.CHANGED);
        }
        entityManager.createNativeQuery("""
                SELECT agreement_id FROM ride_agreements
                WHERE request_id IN (:ids) ORDER BY agreement_id FOR UPDATE
                """).setParameter("ids", ids).getResultList();
        ids.forEach(id -> entityManager.refresh(entityManager.find(RideRequestEntity.class, id)));
        if (statuses.contains("CANCELLED")) {
            return Optional.of(statuses.stream().allMatch("CANCELLED"::equals)
                    ? ManagementConflict.CANCELLED : ManagementConflict.PARTLY_CANCELLED);
        }
        return Optional.empty();
    }

    @Override
    @Transactional
    public Optional<RideRequest> update(RideRequest updatedRequest) {
        var entity = entityManager.find(
                RideRequestEntity.class, updatedRequest.getRequestId());

        if (entity == null) {
            return Optional.empty();
        }

        entity.updateDetails(updatedRequest);
        entityManager.flush();

        return Optional.of(entity.toDomain());
    }

    @Override
    @Transactional
    public boolean cancelForOwner(String ownerEmail, Set<UUID> requestIds) {
        if (requestIds.isEmpty() || requestIds.size() > 2) {
            return false;
        }

        var rides = entityManager.createQuery("""
                select ride from RideRequestEntity ride
                where ride.userEmail = :ownerEmail
                  and ride.id in (:requestIds)
                order by ride.id
                """, RideRequestEntity.class)
                .setParameter("ownerEmail", ownerEmail)
                .setParameter("requestIds", requestIds)
                .setLockMode(LockModeType.PESSIMISTIC_WRITE)
                .getResultList();

        if (rides.size() != requestIds.size()) {
            return false;
        }

        rides.forEach(RideRequestEntity::cancel);
        entityManager.flush();
        return true;
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

        if (excludeUserEmail != null) {
            predicates.add(cb.notEqual(root.get("userEmail"), excludeUserEmail));
        }

        if (status != null && !status.isBlank()) {
            predicates.add(cb.equal(root.get("status"), status));
        }

        if (city != null && !city.isBlank()) {
            predicates.add(cb.equal(cb.lower(root.get("city")), city.trim().toLowerCase()));
        }

        if (rideType != null) {
            predicates.add(cb.equal(root.get("rideType"), rideType));
        }

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

        if (departureTime != null) {
            predicates.add(withinTimeWindow(cb, root.get("departureTime"), departureTime));
        }

        if (arrivalTime != null) {
            predicates.add(withinTimeWindow(cb, root.get("arrivalTime"), arrivalTime));
        }

        query.where(predicates.toArray(new Predicate[0]));

        return entityManager.createQuery(query)
                .getResultList()
                .stream()
                .map(RideRequestEntity::toDomain)
                .toList();
    }

    private static Predicate withinTimeWindow(
            CriteriaBuilder builder, Path<LocalTime> field, LocalTime selectedTime) {
        var window = RideTimeWindow.around(selectedTime);
        if (window.crossesMidnight()) {
            return builder.or(
                    builder.greaterThanOrEqualTo(field, window.start()),
                    builder.lessThanOrEqualTo(field, window.end()));
        }
        return builder.between(field, window.start(), window.end());
    }
}
