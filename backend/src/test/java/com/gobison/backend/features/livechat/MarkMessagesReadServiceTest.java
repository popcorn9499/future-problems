package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.MarkMessagesReadException;
import com.gobison.backend.features.livechat.application.MarkMessagesReadService;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MarkMessagesReadServiceTest {

    private final ConversationRepository conversationRepository = mock(ConversationRepository.class);
    private final MessageRepository messageRepository = mock(MessageRepository.class);
    private final MarkMessagesReadService service =
            new MarkMessagesReadService(conversationRepository, messageRepository);
    private final User user = new User("alice@example.com", "password", "Alice", "User", true);

    @Test
    void marksUnreadMessagesAndReturnsTheirIdsAndCount() {
        when(conversationRepository.findConversations("alice@example.com"))
                .thenReturn(List.of(new Conversation("conv_123", List.of("alice@example.com", "bob@example.com"))));
        when(messageRepository.markUnreadMessagesAsRead(
                org.mockito.ArgumentMatchers.eq("conv_123"),
                org.mockito.ArgumentMatchers.eq("alice@example.com"),
                any(Instant.class)))
                .thenReturn(List.of("msg_001", "msg_002"));

        var response = service.markRead(user, "conv_123");

        assertEquals("conv_123", response.conversationId());
        assertEquals(2, response.markedAsRead());
        assertEquals(List.of("msg_001", "msg_002"), response.messageIds());
        verify(messageRepository).markUnreadMessagesAsRead(
                org.mockito.ArgumentMatchers.eq("conv_123"),
                org.mockito.ArgumentMatchers.eq("alice@example.com"),
                any(Instant.class));
    }

    @Test
    void distinguishesMissingConversationFromNonParticipant() {
        when(conversationRepository.findConversations("alice@example.com")).thenReturn(List.of());
        when(conversationRepository.existsConversation("missing")).thenReturn(false);
        when(conversationRepository.existsConversation("conv_456")).thenReturn(true);

        var notFound = assertThrows(
                MarkMessagesReadException.class,
                () -> service.markRead(user, "missing"));
        var forbidden = assertThrows(
                MarkMessagesReadException.class,
                () -> service.markRead(user, "conv_456"));

        assertEquals(MarkMessagesReadException.Reason.CONVERSATION_NOT_FOUND, notFound.getReason());
        assertEquals(MarkMessagesReadException.Reason.NOT_PARTICIPANT, forbidden.getReason());
    }
}
