package com.gobison.backend.features.auth.application;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SessionAuthenticationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;

import static com.gobison.backend.features.auth.application.RegisterAccountException.Reason.EMAIL_ALREADY_REGISTERED;
import static com.gobison.backend.features.auth.application.RegisterAccountException.Reason.DELETED_ACCOUNT;
import static com.gobison.backend.features.auth.application.RegisterAccountException.Reason.INVALID_REQUEST;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RegisterAccountServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private SessionAuthenticationService sessionAuthenticationService;
    @Mock private HttpServletRequest request;
    @Mock private HttpServletResponse response;

    private RegisterAccountService service;

    @BeforeEach
    void setUp() {
        service = new RegisterAccountService(userRepository, passwordEncoder, sessionAuthenticationService);
    }

    @Test
    void registersNormalizedAccountWithHashedPasswordAndTimestamp() {
        when(passwordEncoder.encode("password")).thenReturn("hashed-password");
        when(userRepository.create(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        Instant beforeRegistration = Instant.now();

        RegisteredAccount result = service.registerAccount(
                " Ada ", " Lovelace ", " ADA@example.com ", "password", request, response);

        Instant afterRegistration = Instant.now();
        assertAll(
                () -> assertEquals("ada@example.com", result.userId()),
                () -> assertEquals("Ada", result.firstName()),
                () -> assertEquals("Lovelace", result.lastName()),
                () -> assertEquals("ada@example.com", result.email()),
                () -> assertNotNull(result.createdAt()),
                () -> assertFalse(result.createdAt().isBefore(beforeRegistration)),
                () -> assertFalse(result.createdAt().isAfter(afterRegistration))
        );
        verify(userRepository).create(argThat(user ->
                user.getEmail().equals("ada@example.com")
                        && user.getPassword().equals("hashed-password")
                        && user.getFirstName().equals("Ada")
                        && user.getLastName().equals("Lovelace")
                        && !user.isVerified()));
        verify(sessionAuthenticationService).establishSession("ada@example.com", request, response);
        verify(userRepository).existsByEmail("ada@example.com");
        verifyNoMoreInteractions(userRepository, passwordEncoder, sessionAuthenticationService);
    }

    @Test
    void rejectsExistingEmailWithoutUpdatingCredentials() {
        when(userRepository.existsByEmail("ada@example.com")).thenReturn(true);
        var exception = assertThrows(RegisterAccountException.class, () -> register("ada@example.com"));
        assertEquals(EMAIL_ALREADY_REGISTERED, exception.getReason());
        verify(userRepository, never()).create(any());
        verify(userRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder, sessionAuthenticationService);
    }

    @Test
    void doesNotAllowDeletedAccountEmailToRegisterAgain() {
        User deletedUser = new User("ada@example.com", "hashed", "Ada", "Lovelace", true);
        deletedUser.setDeleted(true);
        when(userRepository.existsByEmail("ada@example.com")).thenReturn(true);
        when(userRepository.findByEmail("ada@example.com")).thenReturn(java.util.Optional.of(deletedUser));

        RegisterAccountException exception = assertThrows(RegisterAccountException.class,
                () -> register("ada@example.com"));

        assertEquals(DELETED_ACCOUNT, exception.getReason());
        verify(userRepository, never()).create(any());
        verifyNoInteractions(passwordEncoder, sessionAuthenticationService);
    }

    @Test
    void rejectsNullOrBlankNamesAndNullPasswordBeforeDoingWork() {
        assertInvalidRequest(null, "Lovelace", "ada@example.com", "password");
        assertInvalidRequest("  ", "Lovelace", "ada@example.com", "password");
        assertInvalidRequest("Ada", "Lovelace", "ada@example.com", null);

        verifyNoInteractions(userRepository, passwordEncoder, sessionAuthenticationService);
    }

    @Test
    void rejectsMalformedEmailBeforeDoingWork() {
        assertInvalidRequest("Ada", "Lovelace", null, "password");
        assertInvalidRequest("Ada", "Lovelace", "not-an-email", "password");

        verifyNoInteractions(userRepository, passwordEncoder, sessionAuthenticationService);
    }

    @Test
    void mapsConcurrentDuplicateEmailConstraintViolationToConflictReason() {
        when(passwordEncoder.encode("password")).thenReturn("hashed-password");
        when(userRepository.create(any(User.class))).thenThrow(new DataIntegrityViolationException("duplicate"));
        when(userRepository.existsByEmail("ada@example.com")).thenReturn(false, true);

        RegisterAccountException exception = assertThrows(RegisterAccountException.class,
                () -> register("ada@example.com"));

        assertEquals(EMAIL_ALREADY_REGISTERED, exception.getReason());
        verify(userRepository, times(2)).existsByEmail("ada@example.com");
        verifyNoInteractions(sessionAuthenticationService);
    }

    @Test
    void rethrowsUnrelatedPersistenceConstraintViolation() {
        DataIntegrityViolationException persistenceFailure = new DataIntegrityViolationException("constraint");
        when(passwordEncoder.encode("password")).thenReturn("hashed-password");
        when(userRepository.create(any(User.class))).thenThrow(persistenceFailure);
        when(userRepository.existsByEmail("ada@example.com")).thenReturn(false);

        DataIntegrityViolationException thrown = assertThrows(DataIntegrityViolationException.class,
                () -> register("ada@example.com"));

        assertSame(persistenceFailure, thrown);
        verifyNoInteractions(sessionAuthenticationService);
    }

    private void assertInvalidRequest(String firstName, String lastName, String email, String password) {
        RegisterAccountException exception = assertThrows(RegisterAccountException.class,
                () -> service.registerAccount(firstName, lastName, email, password, request, response));
        assertEquals(INVALID_REQUEST, exception.getReason());
    }

    private RegisteredAccount register(String email) {
        return service.registerAccount("Ada", "Lovelace", email, "password", request, response);
    }
}
