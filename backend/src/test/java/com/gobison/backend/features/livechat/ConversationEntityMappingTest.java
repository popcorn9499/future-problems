package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.infrastructure.persistence.ConversationEntity;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;

class ConversationEntityMappingTest {

    @Test
    void preservesConversationFieldsThroughEntityMapping() {
        var conversation = new Conversation("conv_123", List.of("two@example.com", "one@example.com"));

        var restored = new ConversationEntity(conversation).toDomain();

        assertAll(
                () -> assertEquals("conv_123", restored.getId()),
                () -> assertEquals(List.of("one@example.com", "two@example.com"), restored.getParticipants()));
    }
}
