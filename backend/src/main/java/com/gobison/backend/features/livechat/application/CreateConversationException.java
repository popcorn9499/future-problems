package com.gobison.backend.features.livechat.application;

public class CreateConversationException extends RuntimeException {

    public enum Reason {
        INVALID_REQUEST,
        CURRENT_USER_NOT_FOUND,
        SELF_CONVERSATION,
        PARTICIPANT_NOT_FOUND,
        CONVERSATION_ALREADY_EXISTS
    }

    private final Reason reason;

    public CreateConversationException(Reason reason) {
        super(reason.name());
        this.reason = reason;
    }

    public Reason getReason() {
        return reason;
    }
}
