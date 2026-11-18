package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Message;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "messages")
public class MessageEntity {

    @Id
    @Column(name = "message_id", nullable = false, length = 41)
    private String msgId;

    @Column(name = "conversation_id", nullable = false, length = 41)
    private String conversationId;

    @Column(name = "sender_id", nullable = false, length = 254)
    private String senderId;

    @Column(name = "content", nullable = false, columnDefinition = "text")
    private String content;

    @Column(name = "sent_at", nullable = false)
    private Instant sentAt;

    @Column(name = "read_at")
    private Instant readAt;

    protected MessageEntity() {
    }

    public MessageEntity(Message message) {
        msgId = message.getMsgId();
        conversationId = message.getConversationId();
        senderId = message.getSenderId();
        content = message.getContent();
        sentAt = message.getSentAt();
        readAt = message.getReadAt();
    }

    public Message toDomain() {
        return Message.restore(msgId, conversationId, senderId, content, sentAt, readAt);
    }
}
