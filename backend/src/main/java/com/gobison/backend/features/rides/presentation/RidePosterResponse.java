package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.user.domain.model.User;

public record RidePosterResponse(String firstName, String lastName, String avatarColor) {
    static RidePosterResponse from(User user) {
        if (user == null || user.isDeleted()
                || user.getFirstName() == null || user.getFirstName().isBlank()) {
            return null;
        }
        return new RidePosterResponse(user.getFirstName(), user.getLastName(), user.getAvatarColor());
    }
}
