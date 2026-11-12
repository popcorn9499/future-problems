package com.gobison.backend.features.auth.presentation;

import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/auth")
public class CurrentUserController {
    private final UserRepository users;

    public CurrentUserController(UserRepository users) {
        this.users = users;
    }

    @GetMapping("/me")
    public AuthUserResponse currentUser(Authentication authentication) {
        return users.findByEmail(authentication.getName())
                .map(AuthUserResponse::from)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
    }
}
