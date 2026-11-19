package com.gobison.backend.features.livechat.application;

public class GetMessagesException extends RuntimeException {

    public enum Reason {
        USER_NOT_FOUND,
        INVALID_LIMIT,
        CONVERSATION_NOT_FOUND,
        MESSAGE_NOT_FOUND
    }

    private final Reason reason;

    public GetMessagesException(Reason reason) {
        super(reason.name());
        this.reason = reason;
    }

    public Reason getReason() {
        return reason;
    }
}
