package com.gobison.backend.features.auth.presentation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;

public record RegisterAccountRequest(
        @NotBlank
        // TODO maybe implement a size limitation. @Size(max = 100)
        String firstName,

        // TODO maybe implement a size limitation. @Size(max = 100)
        String lastName,

        @NotBlank
        @Email
        String email,

        @NotBlank
        // TODO maybe implement a size limitation @Size(min = 8, max = 128)
        String password
) {
}