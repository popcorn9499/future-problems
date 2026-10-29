package com.gobison.backend.features.auth.presentation;

import com.gobison.backend.features.auth.application.EmailVerificationService;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SessionAuthenticationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@RestController
@RequestMapping("/api/v1/auth")
public class LoginController {
    private final UserRepository users;
    private final PasswordEncoder passwords;
    private final SessionAuthenticationService sessions;
    private final EmailVerificationService verification;

    public LoginController(UserRepository users, PasswordEncoder passwords,
                           SessionAuthenticationService sessions, EmailVerificationService verification) {
        this.users = users;
        this.passwords = passwords;
        this.sessions = sessions;
        this.verification = verification;
    }

    public record LoginRequest(@NotBlank String email, @NotBlank String password) {}

    public record LoginResponse(AuthUserResponse user) {}

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest credentials,
                               HttpServletRequest request, HttpServletResponse response) {
        var user = users.findByEmail(credentials.email().trim().toLowerCase(Locale.ROOT))
                .filter(account -> passwords.matches(credentials.password(), account.getPassword()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!user.isVerified()) {
            verification.sendVerificationCode(user.getEmail());
        }
        sessions.establishSession(user.getEmail(), request, response);
        return new LoginResponse(AuthUserResponse.from(user));
    }
}
