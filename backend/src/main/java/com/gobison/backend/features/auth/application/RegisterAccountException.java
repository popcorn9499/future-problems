package com.gobison.backend.features.auth.application;

public class RegisterAccountException extends RuntimeException {

    public enum Reason {
        INVALID_REQUEST,
        EMAIL_ALREADY_REGISTERED,
        DELETED_ACCOUNT
    }

    private final Reason reason;

    public RegisterAccountException(Reason reason) {
        super(reason.name());
        this.reason = reason;
    }

    public Reason getReason() {
        return reason;
    }
}
