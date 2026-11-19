package com.gobison.backend.features.livechat.domain.model;

import java.time.Instant;

public class Message {
    private final String msgId;
    private final String conversationId;
    private final String senderId;
    private final String content;
    private final Instant sentAt;
    private Instant readAt;

    // Create a new message.
    public Message(String msgId, String conversationId, String senderId, String content) {
        this(msgId, conversationId, senderId, content, Instant.now(), null);
    }

    // Rebuild a message with the timestamps stored in the database.
    public static Message restore(
            String msgId,
            String conversationId,
            String senderId,
            String content,
            Instant sentAt,
            Instant readAt) {
        return new Message(msgId, conversationId, senderId, content, sentAt, readAt);
    }

    private Message(
            String msgId,
            String conversationId,
            String senderId,
            String content,
            Instant sentAt,
            Instant readAt) {
        this.msgId = msgId;
        this.conversationId = conversationId;
        this.senderId = senderId;
        this.content = content;
        this.sentAt = sentAt;
        this.readAt = readAt;
    }

    public String getMsgId() {
        return msgId;
    }

    public String getConversationId() {
        return conversationId;
    }

    public String getSenderId() {
        return senderId;
    }

    public String getContent() {
        return content;
    }

    public Instant getSentAt() {
        return sentAt;
    }

    public Instant getReadAt() {
        return readAt;
    }

    public void markRead() {
        if (readAt == null) {
            readAt = Instant.now();
        }
    }
}