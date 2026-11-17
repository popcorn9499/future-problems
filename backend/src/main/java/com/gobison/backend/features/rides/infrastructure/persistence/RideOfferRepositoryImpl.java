package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

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
}
