package com.gobison.backend.features.user.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserJpaRepository
        extends JpaRepository<UserEntity, String> {

    Optional<UserEntity> findByUmNetId(String umNetId);

    boolean existsByUmNetId(String umNetId);
}