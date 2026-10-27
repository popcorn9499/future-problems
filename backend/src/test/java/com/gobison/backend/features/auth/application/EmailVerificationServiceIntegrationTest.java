package com.gobison.backend.features.auth.application;

import com.gobison.backend.features.auth.infrastructure.email.EmailService;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@SpringBootTest
@Transactional
class EmailVerificationServiceIntegrationTest {

    private static final String TEST_EMAIL = "frontend.integration.test@myumanitoba.ca";

    private static final String TEST_PASSWORD = "test-password";
    private static final String TEST_FIRST_NAME = "Integration";
    private static final String TEST_LAST_NAME = "Test";

    @Autowired
    private EmailVerificationService emailVerificationService;

    @Autowired
    private UserRepository userRepository;

    @PersistenceContext
    private EntityManager entityManager;

    @MockitoBean
    private EmailService emailService;

    @BeforeEach
    void setUp() {
        // Remove a leftover test record from an earlier test run, if present
        userRepository.deleteByEmail(TEST_EMAIL);
        entityManager.flush();
        entityManager.clear();
        userRepository.save(new User(TEST_EMAIL, TEST_PASSWORD, TEST_FIRST_NAME, TEST_LAST_NAME, false));
        entityManager.flush();
        entityManager.clear();
    }

    @AfterEach
    void cleanUp() {
        // Explicit cleanup safeguard
        userRepository.deleteByEmail(TEST_EMAIL);
        entityManager.flush();
        entityManager.clear();
    }

    @Test
    void sendVerificationCode() {
        emailVerificationService.sendVerificationCode(TEST_EMAIL);

        // Force database synchronization and reload the record
        entityManager.flush();
        entityManager.clear();

        User savedUser = userRepository.findByEmail(TEST_EMAIL).orElseThrow();

        assertFalse(savedUser.isVerified());
        assertNotNull(savedUser.getVerificationCode());
        assertTrue(Pattern.matches(
                "[0-9]{6}",
                savedUser.getVerificationCode()
        ));

        verify(emailService).sendVerificationCode(
                eq(TEST_EMAIL),
                eq(savedUser.getVerificationCode())
        );
    }

    @Test
    void verifyEmailCorrectCode() {
        User user = userRepository.findByEmail(TEST_EMAIL).orElseThrow();

        user.setVerificationCode("123456");
        userRepository.save(user);

        entityManager.flush();
        entityManager.clear();

        emailVerificationService.verifyEmail(TEST_EMAIL, "123456");

        entityManager.flush();
        entityManager.clear();

        User savedUser = userRepository.findByEmail(TEST_EMAIL).orElseThrow();
        assertTrue(savedUser.isVerified());
        assertNull(savedUser.getVerificationCode());
    }

    @Test
    void verifyEmailIncorrectCode() {
        User user = userRepository.findByEmail(TEST_EMAIL).orElseThrow();

        user.setVerificationCode("123456");
        userRepository.save(user);

        entityManager.flush();
        entityManager.clear();

        assertThrows(
                EmailVerificationException.class,
                () -> emailVerificationService.verifyEmail(
                        TEST_EMAIL,
                        "654321"
                )
        );

        entityManager.flush();
        entityManager.clear();

        User savedUser = userRepository.findByEmail(TEST_EMAIL).orElseThrow();

        assertFalse(savedUser.isVerified());
        assertEquals("123456", savedUser.getVerificationCode());
    }
}