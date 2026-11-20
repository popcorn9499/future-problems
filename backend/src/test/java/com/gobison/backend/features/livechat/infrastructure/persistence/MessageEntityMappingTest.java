package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.infrastructure.persistence.MessageEntity;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class MessageEntityMappingTest {

    @Test
    void preservesMessageFieldsThroughEntityMapping() {
        var sentAt = Instant.parse("2026-11-10T14:40:00Z");
        var readAt = Instant.parse("2026-11-10T14:45:00Z");
        var message = Message.restore(
                "msg_124", "conv_123", "usr_123", "Are you available on Monday?", sentAt, readAt);

        var restored = new MessageEntity(message).toDomain();

        assertAll(
                () -> assertEquals("msg_124", restored.getMsgId()),
                () -> assertEquals("conv_123", restored.getConversationId()),
                () -> assertEquals("usr_123", restored.getSenderId()),
                () -> assertEquals("Are you available on Monday?", restored.getContent()),
                () -> assertEquals(sentAt, restored.getSentAt()),
                () -> assertEquals(readAt, restored.getReadAt()));
    }

    @Test
    void preservesUnreadMessageWithNullReadAt() {
        var message = new Message("msg_124", "conv_123", "usr_123", "Hello");

        var restored = new MessageEntity(message).toDomain();

        assertNull(restored.getReadAt());
        assertEquals(message.getSentAt(), restored.getSentAt());
    }
}
