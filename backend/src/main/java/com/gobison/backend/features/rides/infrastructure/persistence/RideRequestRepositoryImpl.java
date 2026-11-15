package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

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
}
