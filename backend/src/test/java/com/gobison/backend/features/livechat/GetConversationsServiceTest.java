package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.GetConversationsService;
import com.gobison.backend.features.livechat.application.dto.ConversationSummaryResponse;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class GetConversationsServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final ConversationRepository conversationRepository = mock(ConversationRepository.class);
    private final MessageRepository messageRepository = mock(MessageRepository.class);
    private final GetConversationsService service =
            new GetConversationsService(userRepository, conversationRepository, messageRepository);

    @Test
    void buildsConversationSummaryWithOtherParticipantLatestMessageAndUnreadCount() {
        User currentUser = new User("alice@example.com", "hash", "Alice", "Smith", true);
        User otherUser = new User("bob@example.com", "hash", "Bob", "Jones", true);
        otherUser.setAvatarColor("#123ABC");
        Conversation conversation = new Conversation(
                "conv_123", List.of(currentUser.getEmail(), otherUser.getEmail()));
        Instant sentAt = Instant.parse("2026-11-18T12:00:00Z");
        Message latestMessage = Message.restore(
                "msg_123", conversation.getId(), otherUser.getEmail(), "Hello", sentAt, null);
        when(conversationRepository.findConversations(currentUser.getEmail()))
                .thenReturn(List.of(conversation));
        when(userRepository.findByEmail(otherUser.getEmail())).thenReturn(Optional.of(otherUser));
        when(messageRepository.retrieveLatestMsg(conversation.getId())).thenReturn(latestMessage);
        when(messageRepository.countUnreadMessages(conversation.getId(), currentUser.getEmail()))
                .thenReturn(2L);

        List<ConversationSummaryResponse> summaries = service.getConversations(currentUser);

        assertEquals(1, summaries.size());
        ConversationSummaryResponse summary = summaries.getFirst();
        assertEquals("conv_123", summary.conversationId());
        assertEquals(
                new ConversationSummaryResponse.Participant(
                        "bob@example.com", "Bob", "Jones", "#123ABC"),
                summary.participant());
        assertEquals("Hello", summary.lastMessage());
        assertEquals(sentAt, summary.lastMessageAt());
        assertEquals(2L, summary.unreadCount());
        verify(conversationRepository).findConversations(currentUser.getEmail());
        verify(messageRepository).retrieveLatestMsg(conversation.getId());
        verify(messageRepository).countUnreadMessages(conversation.getId(), currentUser.getEmail());
    }

    @Test
    void returnsEmptyListWhenUserHasNoConversations() {
        User currentUser = new User("alice@example.com", "hash", "Alice", "Smith", true);
        when(conversationRepository.findConversations(currentUser.getEmail())).thenReturn(List.of());

        List<ConversationSummaryResponse> summaries = service.getConversations(currentUser);

        assertEquals(List.of(), summaries);
        verifyNoInteractions(userRepository, messageRepository);
    }

    @Test
    void returnsSummaryWithNullLastMessageWhenConversationHasNoMessages() {
        User currentUser = new User("alice@example.com", "hash", "Alice", "Smith", true);
        User otherUser = new User("bob@example.com", "hash", "Bob", "Jones", true);
        Conversation conversation = new Conversation(
                "conv_123", List.of(currentUser.getEmail(), otherUser.getEmail()));
        when(conversationRepository.findConversations(currentUser.getEmail()))
                .thenReturn(List.of(conversation));
        when(userRepository.findByEmail(otherUser.getEmail())).thenReturn(Optional.of(otherUser));
        when(messageRepository.retrieveLatestMsg(conversation.getId())).thenReturn(null);
        when(messageRepository.countUnreadMessages(conversation.getId(), currentUser.getEmail()))
                .thenReturn(0L);

        ConversationSummaryResponse summary = service.getConversations(currentUser).getFirst();

        assertNull(summary.lastMessage());
        assertNull(summary.lastMessageAt());
        assertEquals(0L, summary.unreadCount());
    }
}
