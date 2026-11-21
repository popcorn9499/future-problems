package com.gobison.backend.features.user.presentation;

import com.gobison.backend.features.user.application.UpdateProfileService;
import com.gobison.backend.features.user.application.DeleteAccountService;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.features.user.presentation.dto.GetProfileResponse;
import com.gobison.backend.features.user.presentation.dto.UpdateProfileRequest;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/users")
public class UserAccountController {
    private final UserRepository users;
    private final UpdateProfileService updateProfileService;
    private final DeleteAccountService deleteAccountService;

    public UserAccountController(
            UserRepository users,
            UpdateProfileService updateProfileService,
            DeleteAccountService deleteAccountService) {
        this.users = users;
        this.updateProfileService = updateProfileService;
        this.deleteAccountService = deleteAccountService;
    }

    @PatchMapping("/me/profile")
    public ResponseEntity<GetProfileResponse> updateProfile(Authentication authentication,
                                                            @Valid @RequestBody UpdateProfileRequest request) {
        var user = users.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        user = updateProfileService.updateProfile(user, request);

        GetProfileResponse response = new GetProfileResponse(
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getAge(),
                user.getPronouns(),
                user.getDescription(),
                user.getAvatarColor()
        );

        return ResponseEntity.ok(response);
    }

    @GetMapping("/me/profile")
    public ResponseEntity<GetProfileResponse> getProfile(Authentication authentication) {
        var user = users.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        GetProfileResponse response = new GetProfileResponse(
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getAge(),
                user.getPronouns(),
                user.getDescription(),
                user.getAvatarColor()
        );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/me")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCurrentAccount(
            Authentication authentication,
            HttpServletRequest request,
            HttpServletResponse response) {
        deleteAccountService.delete(authentication.getName());

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
