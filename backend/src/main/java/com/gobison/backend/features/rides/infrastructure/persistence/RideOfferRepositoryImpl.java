package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

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
}
