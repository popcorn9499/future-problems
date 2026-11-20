package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.application.dto.MarkMessagesReadResponse;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class MarkMessagesReadService {
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;

    public MarkMessagesReadService(
            ConversationRepository conversationRepository,
            MessageRepository messageRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
    }

    public MarkMessagesReadResponse markRead(User user, String conversationId) {
        boolean isParticipant = conversationRepository.findConversations(user.getEmail()).stream()
                .anyMatch(conversation -> conversation.getId().equals(conversationId));
        if (!isParticipant) {
            if (!conversationRepository.existsConversation(conversationId)) {
                throw new MarkMessagesReadException(MarkMessagesReadException.Reason.CONVERSATION_NOT_FOUND);
            }
            throw new MarkMessagesReadException(MarkMessagesReadException.Reason.NOT_PARTICIPANT);
        }

        Instant readAt = Instant.now();
        List<String> markedMessageIds = messageRepository.markUnreadMessagesAsRead(
                conversationId, user.getEmail(), readAt);
        return new MarkMessagesReadResponse(conversationId, markedMessageIds.size(), markedMessageIds, readAt);
    }
}
