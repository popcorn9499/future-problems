package com.gobison.backend.features.auth.presentation;

import com.gobison.backend.features.user.domain.model.User;

public record AuthUserResponse(String userId, String firstName, String lastName, String email, boolean verified) {
    public static AuthUserResponse from(User user) {
        return new AuthUserResponse(user.getEmail(), user.getFirstName(), user.getLastName(),
                user.getEmail(), user.isVerified());
    }
}
