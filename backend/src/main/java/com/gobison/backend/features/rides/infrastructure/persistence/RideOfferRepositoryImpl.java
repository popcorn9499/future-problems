package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

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
}
