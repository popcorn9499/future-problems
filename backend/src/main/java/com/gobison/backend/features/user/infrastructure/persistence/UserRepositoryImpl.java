package com.gobison.backend.features.user.infrastructure.persistence;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityNotFoundException;
import jakarta.persistence.PersistenceContext;

import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

//implements the domain interface by calling the JPA repository and converting between User and UserEntity
@Repository
public class UserRepositoryImpl implements UserRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional
    public User create(User user) {
        UserEntity entity = new UserEntity(user.getEmail(), user.getPassword(),
                user.getFirstName(), user.getLastName(), user.isVerified());
        entity.setAvatarColor(user.getAvatarColor());
        entityManager.persist(entity);
        entityManager.flush();
        return toDomain(entity);
    }

    private final UserJpaRepository jpaRepository;

    public UserRepositoryImpl(UserJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return jpaRepository.findByEmail(email)
                .map(this::toDomain);
    }

    @Override
    public User save(User user) {
        UserEntity entity = new UserEntity(
                user.getEmail(),
                user.getPassword(),
                user.getFirstName(),
                user.getLastName(),
                user.isVerified()
        );
        entity.setVerificationCode(user.getVerificationCode());
        entity.setDeleted(user.isDeleted());
        entity.setGender(user.getGender());
        entity.setAge(user.getAge());
        entity.setDescription(user.getDescription());
        entity.setAvatarColor(user.getAvatarColor());

        UserEntity saved = jpaRepository.save(entity);

        return toDomain(saved);
    }

    @Override
    public boolean existsByEmail(String email) {
        return jpaRepository.existsByEmail(email);
    }

    @Override
    @Transactional
    public void deleteByEmail(String email) {
        jpaRepository.deleteByEmail(email);
    }

    @Override
    @Transactional
    public User update(User user) {
        UserEntity entity = jpaRepository.findByEmail(user.getEmail())
                .orElseThrow(() -> new EntityNotFoundException(
                        "User not found: " + user.getEmail()));

        entity.setGender(user.getGender());
        entity.setAge(user.getAge());
        entity.setDescription(user.getDescription());
        entity.setAvatarColor(user.getAvatarColor());

        return toDomain(jpaRepository.save(entity));
    }

    private User toDomain(UserEntity entity) {
        User user = new User(
                entity.getEmail(),
                entity.getPassword(),
                entity.getFirstName(),
                entity.getLastName(),
                entity.isVerified()
        );
        user.setVerificationCode(entity.getVerificationCode());
        user.setDeleted(entity.isDeleted());
        user.setGender(entity.getGender());
        user.setAge(entity.getAge());
        user.setDescription(entity.getDescription());
        user.setAvatarColor(entity.getAvatarColor());
        return user;
    }
}
