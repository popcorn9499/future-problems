
package com.gobison.backend.features.user.infrastructure.persistence;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;

import org.springframework.stereotype.Repository;

import java.util.Optional;

//implements the domain interface by calling the JPA repository and converting between User and UserEntity
@Repository
public class UserRepositoryImpl implements UserRepository {

    private final UserJpaRepository jpaRepository;

    public UserRepositoryImpl(UserJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Optional<User> findByUmNetId(String umNetId) {
        return jpaRepository.findByUmNetId(umNetId)
                .map(this::toDomain);
    }

    @Override
    public User save(User user) {
        UserEntity entity = new UserEntity(
                user.getUmNetId(),
                user.getPassword(),
                user.getFirstName(),
                user.getLastName(),
                user.isVerified()
        );
                

        UserEntity saved = jpaRepository.save(entity);

        return toDomain(saved);
    }

    @Override
    public boolean existsByUmNetId(String umNetId) {
        return jpaRepository.existsByUmNetId(umNetId);
    }

    @Override
    public void deleteByUmNetId(String umNetId) {
        jpaRepository.deleteById(umNetId);
    }

    private User toDomain(UserEntity entity) {
        return new User(
                entity.getUmNetId(),
                entity.getPassword(),
                entity.getFirstName(),
                entity.getLastName(),
                entity.isVerified()
        );
    }
}