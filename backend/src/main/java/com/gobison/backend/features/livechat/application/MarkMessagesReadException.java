package com.gobison.backend.features.livechat.application;

public class MarkMessagesReadException extends RuntimeException {

    public enum Reason {
        USER_NOT_FOUND,
        CONVERSATION_NOT_FOUND,
        NOT_PARTICIPANT
    }

    private final Reason reason;

    public MarkMessagesReadException(Reason reason) {
        super(reason.name());
        this.reason = reason;
    }

    public Reason getReason() {
        return reason;
    }
}
