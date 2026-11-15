package com.gobison.backend.features.user.presentation;

import com.gobison.backend.features.user.domain.repository.UserRepository;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/users")
public class UserAccountController {
    private final UserRepository users;

    public UserAccountController(UserRepository users) {
        this.users = users;
    }

    @DeleteMapping("/me")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCurrentAccount(
            Authentication authentication,
            HttpServletRequest request,
            HttpServletResponse response) {
        var user = users.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!user.isDeleted()) {
            user.setDeleted(true);
            users.save(user);
        }

        var session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        SecurityContextHolder.clearContext();

        Cookie expiredSession = new Cookie("JSESSIONID", "");
        expiredSession.setPath("/");
        expiredSession.setMaxAge(0);
        expiredSession.setHttpOnly(true);
        response.addCookie(expiredSession);
    }
}
