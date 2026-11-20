package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.application.GetMessagesService;
import com.gobison.backend.features.livechat.application.dto.MessageItem;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class GetMessagesServiceTest {

    private final ConversationRepository conversationRepository = mock(ConversationRepository.class);
    private final MessageRepository messageRepository = mock(MessageRepository.class);
    private final GetMessagesService service = new GetMessagesService(conversationRepository, messageRepository);
    private final User user = new User("alice@example.com", "password", "Alice", "User", true);
    private final Conversation conversation =
            new Conversation("conv_123", List.of("alice@example.com", "bob@example.com"));

    @Test
    void retrievesLatestPageAndDropsExtraMessageUsedToDetectMore() {
        allowConversationAccess();
        when(messageRepository.retrieveMsgs("conv_123", 4)).thenReturn(List.of(
                message("msg_001", "Oldest", "2026-11-18T12:00:00Z"),
                message("msg_002", "First returned", "2026-11-18T12:01:00Z"),
                message("msg_003", "Second returned", "2026-11-18T12:02:00Z"),
                message("msg_004", "Latest", "2026-11-18T12:03:00Z")));

        var response = service.getConversation(user, "conv_123", 3);

        assertEquals("conv_123", response.conversationId());
        assertEquals(List.of("msg_002", "msg_003", "msg_004"),
                response.messages().stream().map(MessageItem::messageId).toList());
        assertEquals("Second returned", response.messages().get(1).content());
        assertEquals(3, response.pagination().limit());
        assertTrue(response.pagination().hasMore());
        assertEquals("msg_002", response.pagination().nextCursor());
        verify(messageRepository).retrieveMsgs("conv_123", 4);
    }

    @Test
    void retrievesMessagesBeforeCursorAndReturnsNoMoreWhenPageIsShort() {
        allowConversationAccess();
        when(messageRepository.existsMessage("conv_123", "msg_005")).thenReturn(true);
        when(messageRepository.retrieveMsgsBefore("conv_123", "msg_005", 3)).thenReturn(List.of(
                message("msg_002", "Earlier", "2026-11-18T12:01:00Z"),
                message("msg_003", "Later", "2026-11-18T12:02:00Z")));

        var response = service.getConversation(user, "conv_123", 2, "msg_005");

        assertEquals(List.of("msg_002", "msg_003"),
                response.messages().stream().map(MessageItem::messageId).toList());
        assertFalse(response.pagination().hasMore());
        assertEquals("msg_002", response.pagination().nextCursor());
        verify(messageRepository).retrieveMsgsBefore("conv_123", "msg_005", 3);
    }

    @Test
    void returnsEmptyPageWithNullCursorWhenConversationHasNoMessages() {
        allowConversationAccess();
        when(messageRepository.retrieveMsgs("conv_123", 6)).thenReturn(List.of());

        var response = service.getConversation(user, "conv_123", 5);

        assertEquals(List.of(), response.messages());
        assertFalse(response.pagination().hasMore());
        assertNull(response.pagination().nextCursor());
    }

    @Test
    void rejectsMissingConversationAndNonParticipantSeparately() {
        when(conversationRepository.existsConversation("missing")).thenReturn(false);
        var missing = assertThrows(
                GetMessagesException.class,
                () -> service.getConversation(user, "missing", 10));
        assertEquals(GetMessagesException.Reason.CONVERSATION_NOT_FOUND, missing.getReason());

        when(conversationRepository.existsConversation("conv_123")).thenReturn(true);
        when(conversationRepository.findConversations("alice@example.com")).thenReturn(List.of());
        var forbidden = assertThrows(
                GetMessagesException.class,
                () -> service.getConversation(user, "conv_123", 10));
        assertEquals(GetMessagesException.Reason.NOT_PARTICIPANT, forbidden.getReason());
        verifyNoInteractions(messageRepository);
    }

    @Test
    void rejectsInvalidLimitAndUnknownCursorBeforeRetrievingMessages() {
        allowConversationAccess();
        var invalidLimit = assertThrows(
                GetMessagesException.class,
                () -> service.getConversation(user, "conv_123", 0));
        assertEquals(GetMessagesException.Reason.INVALID_LIMIT, invalidLimit.getReason());
        verifyNoInteractions(messageRepository);

        when(messageRepository.existsMessage("conv_123", "missing-message")).thenReturn(false);
        var unknownCursor = assertThrows(
                GetMessagesException.class,
                () -> service.getConversation(user, "conv_123", 10, "missing-message"));
        assertEquals(GetMessagesException.Reason.MESSAGE_NOT_FOUND, unknownCursor.getReason());
        verify(messageRepository).existsMessage("conv_123", "missing-message");
    }

    @Test
    void doesNotOverflowFetchLimitAtIntegerMaximum() {
        allowConversationAccess();
        when(messageRepository.retrieveMsgs("conv_123", Integer.MAX_VALUE)).thenReturn(List.of());

        var response = service.getConversation(user, "conv_123", Integer.MAX_VALUE);

        assertEquals(Integer.MAX_VALUE, response.pagination().limit());
        assertFalse(response.pagination().hasMore());
        verify(messageRepository).retrieveMsgs("conv_123", Integer.MAX_VALUE);
    }

    private void allowConversationAccess() {
        when(conversationRepository.existsConversation("conv_123")).thenReturn(true);
        when(conversationRepository.findConversations("alice@example.com")).thenReturn(List.of(conversation));
    }

    private static Message message(String id, String content, String sentAt) {
        return Message.restore(
                id,
                "conv_123",
                "bob@example.com",
                content,
                Instant.parse(sentAt),
                null);
    }
}
