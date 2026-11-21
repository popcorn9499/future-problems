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
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class RideOfferRepositoryImpl implements RideOfferRepository {

    @Override
    @Transactional
    public void cancelOpenForOwner(String ownerEmail) {
        entityManager.createQuery("""
                UPDATE RideOfferEntity ride SET ride.status = 'CANCELLED'
                WHERE ride.userEmail = :ownerEmail AND ride.status = 'OPEN'
                """).setParameter("ownerEmail", ownerEmail).executeUpdate();
    }

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
    public Optional<RideOffer> findById(UUID offerId) {
        var entity = entityManager.find(RideOfferEntity.class, offerId);
        return Optional.ofNullable(entity).map(RideOfferEntity::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public List<RideOffer> findRoundTripLegs(UUID roundTripId, String ownerEmail) {
        return entityManager.createQuery("""
                select leg from RideOfferEntity leg
                where leg.roundTripId = :roundTripId and leg.userEmail = :ownerEmail
                """, RideOfferEntity.class)
                .setParameter("roundTripId", roundTripId)
                .setParameter("ownerEmail", ownerEmail)
                .getResultList()
                .stream()
                .map(RideOfferEntity::toDomain)
                .toList();
    }

    @Override
    @Transactional
    public Optional<List<RideOffer>> updateIfEditable(String ownerEmail, List<RideOffer> editedLegs) {
        var ids = editedLegs.stream().map(RideOffer::getOfferId).toList();
        var statuses = lockOfferStatuses(ownerEmail, ids);
        if (statuses.size() != ids.size() || statuses.contains("CANCELLED")) {
            return Optional.empty();
        }
        return hasOtherParticipantsUnderLock(ownerEmail, ids) ? Optional.empty() : updateAll(editedLegs);
    }

    @Override
    @Transactional
    public CancellationResult cancelForOwner(String ownerEmail, List<UUID> offerIds, boolean confirmParticipants) {
        if (offerIds.isEmpty() || offerIds.size() > 2) {
            return CancellationResult.OFFER_CHANGED;
        }
        var statuses = lockOfferStatuses(ownerEmail, offerIds);
        if (statuses.size() != offerIds.size()) {
            return CancellationResult.OFFER_CHANGED;
        }
        if (statuses.stream().allMatch("CANCELLED"::equals)) {
            return CancellationResult.CANCELLED;
        }
        if (!confirmParticipants && hasOtherParticipantsUnderLock(ownerEmail, offerIds)) {
            return CancellationResult.CONFIRMATION_REQUIRED;
        }

        entityManager.createNativeQuery("""
                UPDATE ride_offers SET status = 'CANCELLED'
                WHERE user_email = :owner AND offer_id IN (:ids)
                """).setParameter("owner", ownerEmail).setParameter("ids", offerIds).executeUpdate();
        return CancellationResult.CANCELLED;
    }

    private List<?> lockOfferStatuses(String ownerEmail, List<UUID> ids) {
        return entityManager.createNativeQuery("""
                SELECT status FROM ride_offers
                WHERE user_email = :owner AND offer_id IN (:ids)
                ORDER BY offer_id FOR UPDATE
                """).setParameter("owner", ownerEmail).setParameter("ids", ids).getResultList();
    }

    private boolean hasOtherParticipantsUnderLock(String ownerEmail, List<UUID> ids) {
        entityManager.createNativeQuery("""
                SELECT agreement_id FROM ride_agreements
                WHERE offer_id IN (:ids) ORDER BY agreement_id FOR UPDATE
                """).setParameter("ids", ids).getResultList();
        var joined = entityManager.createNativeQuery("""
                SELECT EXISTS (
                    SELECT 1 FROM ride_agreements a
                    JOIN ride_agreement_members m ON m.agreement_id = a.agreement_id
                    WHERE a.offer_id IN (:ids) AND m.user_email <> :owner
                )
                """).setParameter("ids", ids).setParameter("owner", ownerEmail).getSingleResult();
        return Boolean.TRUE.equals(joined);
    }

    Optional<List<RideOffer>> updateAll(List<RideOffer> editedLegs) {
        var entities = new ArrayList<RideOfferEntity>(editedLegs.size());
        for (var leg : editedLegs) {
            var entity = entityManager.find(RideOfferEntity.class, leg.getOfferId());
            if (entity == null) {
                return Optional.empty();
            }
            entityManager.refresh(entity);
            entities.add(entity);
        }

        for (int i = 0; i < editedLegs.size(); i++) {
            entities.get(i).updateDetails(editedLegs.get(i));
        }
        entityManager.flush();
        return Optional.of(entities.stream().map(RideOfferEntity::toDomain).toList());
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

        StringBuilder jpql = new StringBuilder("SELECT e FROM RideOfferEntity e")
                .append(userEmail == null ? " WHERE 1 = 1" : " WHERE e.userEmail != :userEmail");
        var departureWindow = departureTime == null ? null : RideTimeWindow.around(departureTime);
        var arrivalWindow = arrivalTime == null ? null : RideTimeWindow.around(arrivalTime);

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
        if (departureWindow != null) {
            appendTimeWindow(jpql, "departureTime", departureWindow);
        }
        if (arrivalWindow != null) {
            appendTimeWindow(jpql, "arrivalTime", arrivalWindow);
        }
        if (daysOfWeek != null && !daysOfWeek.isEmpty()) {
            jpql.append(" AND (SELECT COUNT(d) FROM e.daysOfWeek d WHERE d IN :daysOfWeek) = :dayCount");
        }

        var query = entityManager.createQuery(jpql.toString(), RideOfferEntity.class);
        if (userEmail != null) {
            query.setParameter("userEmail", userEmail);
        }

        if (status != null && !status.isBlank()) {
            query.setParameter("status", status.trim());
        }
        if (city != null && !city.isBlank()) {
            query.setParameter("city", city.trim());
        }
        if (rideType != null) {
            query.setParameter("rideType", rideType);
        }
        if (departureWindow != null) {
            query.setParameter("departureTimeStart", departureWindow.start());
            query.setParameter("departureTimeEnd", departureWindow.end());
        }
        if (arrivalWindow != null) {
            query.setParameter("arrivalTimeStart", arrivalWindow.start());
            query.setParameter("arrivalTimeEnd", arrivalWindow.end());
        }
        if (daysOfWeek != null && !daysOfWeek.isEmpty()) {
            query.setParameter("daysOfWeek", daysOfWeek);
            query.setParameter("dayCount", (long) daysOfWeek.size());
        }

        return query.getResultList().stream()
                .map(RideOfferEntity::toDomain)
                .toList();
    }

    private static void appendTimeWindow(StringBuilder jpql, String field, RideTimeWindow window) {
        if (window.crossesMidnight()) {
            jpql.append(" AND (e.%1$s >= :%1$sStart OR e.%1$s <= :%1$sEnd)".formatted(field));
        } else {
            jpql.append(" AND e.%1$s BETWEEN :%1$sStart AND :%1$sEnd".formatted(field));
        }
    }
}
