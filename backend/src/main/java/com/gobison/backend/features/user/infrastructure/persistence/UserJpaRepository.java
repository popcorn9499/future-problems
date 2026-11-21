package com.gobison.backend.features.user.infrastructure.persistence;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UserJpaRepository
        extends JpaRepository<UserEntity, String> {

    Optional<UserEntity> findByEmail(String email);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from UserEntity u where u.email = :email and u.deleted = false")
    Optional<UserEntity> lockActiveByEmail(@Param("email") String email);

    boolean existsByEmail(String email);

    void deleteByEmail(String email);
}
