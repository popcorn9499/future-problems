package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.application.SendMessageException;
import com.gobison.backend.features.livechat.application.SendMessageService;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class SendMessageServiceTest {

    private final ConversationRepository conversationRepository = mock(ConversationRepository.class);
    private final MessageRepository messageRepository = mock(MessageRepository.class);
    private final SendMessageService service = new SendMessageService(conversationRepository, messageRepository);
    private final User user = new User("alice@example.com", "password", "Alice", "User", true);

    @Test
    void sendsMessageForConversationParticipant() {
        var conversation = new Conversation("conv_123", List.of("alice@example.com", "bob@example.com"));
        var message = Message.restore(
                "msg_123", "conv_123", "alice@example.com", "Hello", java.time.Instant.now(), null);
        when(conversationRepository.findConversations("alice@example.com")).thenReturn(List.of(conversation));
        when(messageRepository.saveMsg("Hello", "conv_123", "alice@example.com"))
                .thenReturn(new MessageRepository.CreateResult(message, true));

        assertEquals(message, service.send(user, "conv_123", "Hello"));
        verify(messageRepository).saveMsg("Hello", "conv_123", "alice@example.com");
    }

    @Test
    void rejectsBlankContent() {
        var exception = assertThrows(
                SendMessageException.class,
                () -> service.send(user, "conv_123", "  "));

        assertEquals(SendMessageException.Reason.INVALID_CONTENT, exception.getReason());
        verifyNoInteractions(conversationRepository, messageRepository);
    }

    @Test
    void distinguishesMissingConversationFromNonParticipant() {
        when(conversationRepository.findConversations("alice@example.com")).thenReturn(List.of());
        when(conversationRepository.existsConversation("missing")).thenReturn(false);
        when(conversationRepository.existsConversation("conv_123")).thenReturn(true);

        var notFound = assertThrows(
                SendMessageException.class,
                () -> service.send(user, "missing", "Hello"));
        var forbidden = assertThrows(
                SendMessageException.class,
                () -> service.send(user, "conv_123", "Hello"));

        assertEquals(SendMessageException.Reason.CONVERSATION_NOT_FOUND, notFound.getReason());
        assertEquals(SendMessageException.Reason.NOT_PARTICIPANT, forbidden.getReason());
    }
}
