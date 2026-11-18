package com.gobison.backend.features.user.presentation.dto;

import java.time.Instant;

public record GetProfileResponse(
        String userId,
        String firstName,
        String lastName,
        Integer age,
        String gender,
        String description
) {
}
