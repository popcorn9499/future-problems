package com.gobison.backend.features.user.infrastructure.persistence;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class UserRepositoryImplTest {

    @Autowired
    private UserRepository userRepository;

    private final List<String> testUserIds = new ArrayList<>();

    private User createTestUser(String firstName, String lastName, boolean verified) {
        String umNetId = "test_" + UUID.randomUUID().toString().replace("-", "");
        testUserIds.add(umNetId);
        return new User(umNetId, "test-hash-not-a-real-password", firstName, lastName, verified);
    }

    @AfterEach
    void cleanUp() {
        for (String umNetId : testUserIds) {
            userRepository.deleteByUmNetId(umNetId);
        }
        testUserIds.clear();
    }

    @Test
    void shouldSaveUserAndReturnAllFields() {
        User user = createTestUser("Test", "Student", false);

        User saved = userRepository.save(user);

        assertAll(
                () -> assertEquals(user.getUmNetId(), saved.getUmNetId()),
                () -> assertEquals(user.getPassword(), saved.getPassword()),
                () -> assertEquals(user.getFirstName(), saved.getFirstName()),
                () -> assertEquals(user.getLastName(), saved.getLastName()),
                () -> assertEquals(user.isVerified(), saved.isVerified())
        );
    }

    @Test
    void shouldFindExistingUserWithAllFields() {
        User user = createTestUser("Kamryn", "Janke", false);
        userRepository.save(user);

        Optional<User> result = userRepository.findByUmNetId(user.getUmNetId());

        assertTrue(result.isPresent());

        User retrieved = result.orElseThrow();

        assertAll(
                () -> assertEquals(user.getUmNetId(), retrieved.getUmNetId()),
                () -> assertEquals(user.getPassword(), retrieved.getPassword()),
                () -> assertEquals("Kamryn", retrieved.getFirstName()),
                () -> assertEquals("Janke", retrieved.getLastName()),
                () -> assertFalse(retrieved.isVerified())
        );
    }

    @Test
    void shouldReturnEmptyWhenUserDoesNotExist() {
        String umNetId = "missing_" + UUID.randomUUID().toString().replace("-", "");

        Optional<User> result =userRepository.findByUmNetId(umNetId);

        assertTrue(result.isEmpty());
    }

    @Test
    void shouldReturnTrueWhenUserExists() {
        User user = createTestUser("Sasha", "Coles", false);
        userRepository.save(user);

        assertTrue(userRepository.existsByUmNetId(user.getUmNetId()));
    }

    @Test
    void shouldReturnFalseWhenUserDoesNotExist() {
        String umNetId = "missing_" + UUID.randomUUID().toString().replace("-", "");

        assertFalse(userRepository.existsByUmNetId(umNetId));
    }

    @Test
    void shouldDeleteExistingUser() {
        User user = createTestUser("Lauren", "H", false);
        userRepository.save(user);

        assertTrue(
                userRepository.existsByUmNetId(user.getUmNetId())
        );

        userRepository.deleteByUmNetId(user.getUmNetId());

        assertFalse(
                userRepository.existsByUmNetId(user.getUmNetId())
        );
        assertTrue(
                userRepository.findByUmNetId(user.getUmNetId()).isEmpty()
        );
    }

    @Test
    void shouldPreserveVerifiedStatusWhenSavingUser() {
        User user = createTestUser("Stefan", "Salvatore", true);

        User saved = userRepository.save(user);

        Optional<User> result = userRepository.findByUmNetId(saved.getUmNetId());

        assertTrue(result.isPresent());
        assertTrue(result.orElseThrow().isVerified());
    }

    @Test
    void shouldStoreMultipleUsersIndependently() {
        User first = createTestUser("First", "Student", false);
        User second = createTestUser("Second", "Student", true);

        userRepository.save(first);
        userRepository.save(second);

        Optional<User> firstResult = userRepository.findByUmNetId(first.getUmNetId());
        Optional<User> secondResult = userRepository.findByUmNetId(second.getUmNetId());

        assertTrue(firstResult.isPresent());
        assertTrue(secondResult.isPresent());

        assertAll(
                () -> assertEquals("First", firstResult.orElseThrow().getFirstName()),
                () -> assertEquals("Second", secondResult.orElseThrow().getFirstName()),
                () -> assertFalse(firstResult.orElseThrow().isVerified()),
                () -> assertTrue(secondResult.orElseThrow().isVerified())
        );
    }

    @Test
    void shouldUpdateExistingUserWhenSavedAgain() {
        User original = createTestUser("Original", "Name", false);
        userRepository.save(original);

        User updated = new User(
                original.getUmNetId(),
                original.getPassword(),
                "Updated",
                "Name",
                true
        );

        userRepository.save(updated);

        Optional<User> result = userRepository.findByUmNetId(original.getUmNetId());

        assertTrue(result.isPresent());

        User retrieved = result.orElseThrow();

        assertAll(
                () -> assertEquals("Updated", retrieved.getFirstName()),
                () -> assertEquals("Name", retrieved.getLastName()),
                () -> assertTrue(retrieved.isVerified())
        );
    }
}