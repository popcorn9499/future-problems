package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.application.dto.RetrieveMessage;
import com.gobison.backend.features.livechat.application.dto.MessageItem;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class GetMessagesService {
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;

    public GetMessagesService(
            ConversationRepository conversationRepository,
            MessageRepository messageRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
    }

    public RetrieveMessage getConversation(User user, String converastionId, int limit) {
        return getConversation(user, converastionId, limit, null);
    }

    public RetrieveMessage getConversation(User user, String converastionId, int limit, String before) {
        ensureConversationExists(user, converastionId);

        if (limit < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Limit must be greater than zero");
        }

        if (before != null && !messageRepository.existsMessage(converastionId, before)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found");
        }

        int fetchLimit = limit;
        if (limit < Integer.MAX_VALUE) {
            fetchLimit++;
        }

        List<Message> fetchedMessages;
        if (before == null) {
            fetchedMessages = messageRepository.retrieveMsgs(converastionId, fetchLimit);
        } else {
            fetchedMessages = messageRepository.retrieveMsgsBefore(converastionId, before, fetchLimit);
        }

        boolean hasMore = fetchedMessages.size() > limit;
        List<Message> messages = fetchedMessages;
        if (hasMore) {
            messages = fetchedMessages.subList(1, fetchedMessages.size());
        }

        List<MessageItem> messageItems = messages.stream()
                .map(message -> new MessageItem(
                        message.getMsgId(),
                        message.getSenderId(),
                        message.getContent(),
                        message.getSentAt(),
                        message.getReadAt()))
                .toList();
        String nextCursor = null;
        if (!messages.isEmpty()) {
            nextCursor = messages.getFirst().getMsgId();
        }

        return new RetrieveMessage(
                converastionId,
                messageItems,
                new RetrieveMessage.Pagination(limit, hasMore, nextCursor));
    }

    private void ensureConversationExists(User user, String conversationId) {
        boolean exists = conversationRepository.findConversations(user.getEmail()).stream()
                .anyMatch(conversation -> conversation.getId().equals(conversationId));

        if (!exists) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Conversation not found");
        }
    }

}
