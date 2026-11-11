package com.gobison.backend.features.dashboard.domain.model;

/**
 * A person attached to a ride agreement (a driver or a passenger).
 * The email doubles as the user id, matching the rest of the backend.
 */
public record AgreementMember(
        String email,
        String firstName,
        String lastName,
        String address
) {
}