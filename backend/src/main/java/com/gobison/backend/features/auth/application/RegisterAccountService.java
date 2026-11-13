package com.gobison.backend.features.auth.application;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SessionAuthenticationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.regex.Pattern;
import java.time.Instant;

import static com.gobison.backend.features.auth.application.RegisterAccountException.Reason.*;

@Service
public class RegisterAccountService {

    private static final Pattern EMAIL_FORMAT = Pattern.compile(
            "^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\\.[A-Za-z]{2,63}$"
    );

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final SessionAuthenticationService sessionAuthenticationService;

    public RegisterAccountService(UserRepository userRepository,
                                  PasswordEncoder passwordEncoder,
                                  SessionAuthenticationService sessionAuthenticationService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.sessionAuthenticationService = sessionAuthenticationService;
    }

    public RegisteredAccount registerAccount(String firstName, String lastName, String email, String password,
                                             HttpServletRequest request, HttpServletResponse response) {
        if (firstName == null || firstName.isBlank()
                || password == null ) {
            throw new RegisterAccountException(INVALID_REQUEST);
        }

        String normalizedEmail = email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
        if (!EMAIL_FORMAT.matcher(normalizedEmail).matches()) {
            throw new RegisterAccountException(INVALID_REQUEST);
        }
        if (userRepository.existsByEmail(normalizedEmail)) {
            boolean deletedAccount = userRepository.findByEmail(normalizedEmail)
                    .map(User::isDeleted)
                    .orElse(false);
            if (deletedAccount) {
                throw new RegisterAccountException(DELETED_ACCOUNT);
            }
            throw new RegisterAccountException(EMAIL_ALREADY_REGISTERED);
        }
        // TODO consider storing when accounts were created for record keeping purposes
        Instant createdAt = Instant.now();
        User user = new User(normalizedEmail, passwordEncoder.encode(password), firstName.trim(), lastName == null ? "" : lastName.trim(),
                false);
        User savedUser;
        try {
            savedUser = userRepository.create(user);
        } catch (DataIntegrityViolationException exception) {
            // A concurrent registration can pass the existence checks; the database uniqueness constraint wins.
            if (userRepository.existsByEmail(normalizedEmail)) {
                boolean deletedAccount = userRepository.findByEmail(normalizedEmail)
                        .map(User::isDeleted)
                        .orElse(false);
                if (deletedAccount) {
                    throw new RegisterAccountException(DELETED_ACCOUNT);
                }
                throw new RegisterAccountException(EMAIL_ALREADY_REGISTERED);
            }
            throw exception;
        }

        sessionAuthenticationService.establishSession(normalizedEmail, request, response);
        return new RegisteredAccount(
                savedUser.getEmail(),
                savedUser.getFirstName(),
                savedUser.getLastName(),
                savedUser.getEmail(),
                createdAt
        );
    }
}
