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

    private final List<String> testEmails = new ArrayList<>();

    private User createTestUser(String firstName, String lastName, boolean verified) {
        String umNetId = "test_" + UUID.randomUUID().toString().replace("-", "");
        String email = umNetId + "@myumanitoba.ca";
        testEmails.add(umNetId+"@myumanitoba.ca");
        return new User(email, "test-hash-not-a-real-password", firstName, lastName, verified);
    }

    @AfterEach
    void cleanUp() {
        for (String email : testEmails) {
            userRepository.deleteByEmail(email);
        }
        testEmails.clear();
    }

    @Test
    void concurrentCreatesCannotOverwriteAnAccount() throws Exception {
        User first = createTestUser("First", "Student", false);
        User second = new User(first.getEmail(), "different-password", "Second", "Student", false);
        var start = new java.util.concurrent.CountDownLatch(1);
        try (var executor = java.util.concurrent.Executors.newFixedThreadPool(2)) {
            var tasks = new ArrayList<java.util.concurrent.Future<Boolean>>();
            for (User candidate : List.of(first, second)) {
                tasks.add(executor.submit(() -> {
                    start.await();
                    try {
                        userRepository.create(candidate);
                        return true;
                    } catch (org.springframework.dao.DataIntegrityViolationException duplicate) {
                        return false;
                    }
                }));
            }
            start.countDown();
            int successes = 0;
            for (var task : tasks) {
                if (task.get(15, java.util.concurrent.TimeUnit.SECONDS)) successes++;
            }
            assertEquals(1, successes);
        }
        var saved = userRepository.findByEmail(first.getEmail()).orElseThrow();
        assertEquals(saved.getFirstName().equals("First") ? first.getPassword() : second.getPassword(),
                saved.getPassword());
    }

    @Test
    void shouldSaveUserAndReturnAllFields() {
        User user = createTestUser("Test", "Student", false);

        User saved = userRepository.save(user);

        assertAll(
                () -> assertEquals(user.getEmail(), saved.getEmail()),
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

        Optional<User> result = userRepository.findByEmail(user.getEmail());

        assertTrue(result.isPresent());

        User retrieved = result.orElseThrow();

        assertAll(
                () -> assertEquals(user.getEmail(), retrieved.getEmail()),
                () -> assertEquals(user.getPassword(), retrieved.getPassword()),
                () -> assertEquals("Kamryn", retrieved.getFirstName()),
                () -> assertEquals("Janke", retrieved.getLastName()),
                () -> assertFalse(retrieved.isVerified())
        );
    }

    @Test
    void shouldReturnEmptyWhenUserDoesNotExist() {
        String umNetId = "missing_" + UUID.randomUUID().toString().replace("-", "");

        Optional<User> result =userRepository.findByEmail(umNetId+"@myumanitoba.ca");

        assertTrue(result.isEmpty());
    }

    @Test
    void shouldReturnTrueWhenUserExists() {
        User user = createTestUser("Sasha", "Coles", false);
        userRepository.save(user);

        assertTrue(userRepository.existsByEmail(user.getEmail()));
    }

    @Test
    void shouldReturnFalseWhenUserDoesNotExist() {
        String umNetId = "missing_" + UUID.randomUUID().toString().replace("-", "");

        assertFalse(userRepository.existsByEmail(umNetId));
    }

    @Test
    void shouldDeleteExistingUser() {
        User user = createTestUser("Lauren", "H", false);
        userRepository.save(user);

        assertTrue(
                userRepository.existsByEmail(user.getEmail())
        );

        userRepository.deleteByEmail(user.getEmail());

        assertFalse(
                userRepository.existsByEmail(user.getEmail())
        );
        assertTrue(
                userRepository.findByEmail(user.getEmail()).isEmpty()
        );
    }

    @Test
    void shouldPreserveVerifiedStatusWhenSavingUser() {
        User user = createTestUser("Stefan", "Salvatore", true);

        User saved = userRepository.save(user);

        Optional<User> result = userRepository.findByEmail(saved.getEmail());

        assertTrue(result.isPresent());
        assertTrue(result.orElseThrow().isVerified());
    }

    @Test
    void shouldStoreMultipleUsersIndependently() {
        User first = createTestUser("First", "Student", false);
        User second = createTestUser("Second", "Student", true);

        userRepository.save(first);
        userRepository.save(second);

        Optional<User> firstResult = userRepository.findByEmail(first.getEmail());
        Optional<User> secondResult = userRepository.findByEmail(second.getEmail());

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
                original.getEmail(),
                original.getPassword(),
                "Updated",
                "Name",
                true
        );

        userRepository.save(updated);

        Optional<User> result = userRepository.findByEmail(original.getEmail());

        assertTrue(result.isPresent());

        User retrieved = result.orElseThrow();

        assertAll(
                () -> assertEquals("Updated", retrieved.getFirstName()),
                () -> assertEquals("Name", retrieved.getLastName()),
                () -> assertTrue(retrieved.isVerified())
        );
    }

    @Test
    void shouldUpdateProfileWithoutOverwritingCredentialsOrVerificationStatus() {
        User original = createTestUser("Original", "Name", true);
        userRepository.save(original);

        User profileUpdate = new User(
                original.getEmail(),
                "ignored-password",
                "Ignored",
                "Updated",
                false
        );
        profileUpdate.setPronouns("Other");
        profileUpdate.setAge(25);
        profileUpdate.setDescription("A short profile");
        profileUpdate.setAvatarColor("#123ABC");

        User updated = userRepository.update(profileUpdate);

        assertAll(
                () -> assertEquals(original.getPassword(), updated.getPassword()),
                () -> assertEquals("Ignored", updated.getFirstName()),
                () -> assertEquals("Updated", updated.getLastName()),
                () -> assertTrue(updated.isVerified()),
                () -> assertEquals("Other", updated.getPronouns()),
                () -> assertEquals(25, updated.getAge()),
                () -> assertEquals("A short profile", updated.getDescription()),
                () -> assertEquals("#123ABC", updated.getAvatarColor())
        );
    }

    @Test
    void newUsersReceiveDefaultAvatarColor() {
        User user = createTestUser("Default", "Avatar", false);

        User saved = userRepository.create(user);

        assertEquals(User.DEFAULT_AVATAR_COLOR, saved.getAvatarColor());
    }
}
