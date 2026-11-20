package com.gobison.backend.features.livechat.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class MessageTest {

    @Test
    void createsNewMessageWithCurrentSentAtAndNoReadAt() {
        Instant beforeCreation = Instant.now();

        Message message = new Message("msg_124", "conv_123", "usr_123", "Are you available on Monday?");

        Instant afterCreation = Instant.now();
        assertAll(
                () -> assertEquals("msg_124", message.getMsgId()),
                () -> assertEquals("conv_123", message.getConversationId()),
                () -> assertEquals("usr_123", message.getSenderId()),
                () -> assertEquals("Are you available on Monday?", message.getContent()),
                () -> assertTrue(!message.getSentAt().isBefore(beforeCreation)
                        && !message.getSentAt().isAfter(afterCreation)),
                () -> assertNull(message.getReadAt())
        );
    }

    @Test
    void restoresMessageWithStoredTimestamps() {
        Instant sentAt = Instant.parse("2026-11-10T14:40:00Z");
        Instant readAt = Instant.parse("2026-11-10T14:45:00Z");

        Message message = Message.restore(
                "msg_124", "conv_123", "usr_123", "Are you available on Monday?", sentAt, readAt);

        assertAll(
                () -> assertEquals("msg_124", message.getMsgId()),
                () -> assertEquals("conv_123", message.getConversationId()),
                () -> assertEquals("usr_123", message.getSenderId()),
                () -> assertEquals("Are you available on Monday?", message.getContent()),
                () -> assertEquals(sentAt, message.getSentAt()),
                () -> assertEquals(readAt, message.getReadAt())
        );
    }

    @Test
    void restoresUnreadMessageWithNullReadAt() {
        Instant sentAt = Instant.parse("2026-11-10T14:40:00Z");

        Message message = Message.restore("msg_124", "conv_123", "usr_123", "Hello", sentAt, null);

        assertEquals(sentAt, message.getSentAt());
        assertNull(message.getReadAt());
    }

    @Test
    void marksMessageReadOnlyOnce() {
        Message message = Message.restore(
                "msg_124",
                "conv_123",
                "usr_123",
                "Hello",
                Instant.parse("2026-11-10T14:40:00Z"),
                null);

        Instant beforeMarkingRead = Instant.now();
        message.markRead();
        Instant readAt = message.getReadAt();
        Instant afterMarkingRead = Instant.now();
        message.markRead();

        assertAll(
                () -> assertNotNull(readAt),
                () -> assertTrue(!readAt.isBefore(beforeMarkingRead) && !readAt.isAfter(afterMarkingRead)),
                () -> assertEquals(readAt, message.getReadAt())
        );
    }
}
