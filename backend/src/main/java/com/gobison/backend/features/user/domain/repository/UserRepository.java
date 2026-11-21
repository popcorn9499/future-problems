package com.gobison.backend.features.user.domain.repository;

import com.gobison.backend.features.user.domain.model.User;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

public interface UserRepository {
    record CreateResult(User user, boolean created) {}

    Optional<User> findByEmail(String email);
    Optional<User> lockActiveByEmail(String email);
    Map<String, User> findAllByEmail(Collection<String> emails);
    User save(User user);
    User create(User user);
    boolean existsByEmail(String email);
    void deleteByEmail(String email);
    User update(User user);
}

