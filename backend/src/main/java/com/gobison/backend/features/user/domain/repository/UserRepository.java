package com.gobison.backend.features.user.domain.repository;

import com.gobison.backend.features.user.domain.model.User;
import java.util.Optional;

public interface UserRepository {
    Optional<User> findByUmNetId(String umNetId);
    User save(User user);
    boolean existsByUmNetId(String umNetId);
    void deleteByUmNetId(String umNetId);
}

