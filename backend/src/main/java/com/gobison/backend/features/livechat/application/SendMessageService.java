package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.springframework.stereotype.Service;

@Service
public class SendMessageService {
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;

    public SendMessageService(
            ConversationRepository conversationRepository,
            MessageRepository messageRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
    }

    public Message send(User user, String conversationId, String content) {
        if (content == null || content.isBlank()) {
            throw new SendMessageException(SendMessageException.Reason.INVALID_CONTENT);
        }

        boolean isParticipant = conversationRepository.findConversations(user.getEmail()).stream()
                .anyMatch(conversation -> conversation.getId().equals(conversationId));
        if (!isParticipant) {
            if (!conversationRepository.existsConversation(conversationId)) {
                throw new SendMessageException(SendMessageException.Reason.CONVERSATION_NOT_FOUND);
            }
            throw new SendMessageException(SendMessageException.Reason.NOT_PARTICIPANT);
        }

        return messageRepository.saveMsg(content, conversationId, user.getEmail()).message();
    }
}
