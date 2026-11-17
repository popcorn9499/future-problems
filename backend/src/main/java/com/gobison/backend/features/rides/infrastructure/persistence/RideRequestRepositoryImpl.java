package com.gobison.backend.features.rides.infrastructure.persistence;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
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
}