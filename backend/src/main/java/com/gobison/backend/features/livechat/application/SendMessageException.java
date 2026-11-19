package com.gobison.backend.features.livechat.application;

public class SendMessageException extends RuntimeException {

    public enum Reason {
        INVALID_CONTENT,
        CONVERSATION_NOT_FOUND,
        NOT_PARTICIPANT
    }

    private final Reason reason;

    public SendMessageException(Reason reason) {
        super(reason.name());
        this.reason = reason;
    }

    public Reason getReason() {
        return reason;
    }
}
