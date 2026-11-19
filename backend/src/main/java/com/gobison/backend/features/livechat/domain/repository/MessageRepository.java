package com.gobison.backend.features.livechat.domain.repository;

import com.gobison.backend.features.livechat.domain.model.Message;

import java.time.Instant;
import java.util.List;

public interface MessageRepository {
    Message retrieveLatestMsg(String conversationId);

    boolean existsMessage(String conversationId, String messageId);

    long countUnreadMessages(String conversationId, String userId);

    List<String> markUnreadMessagesAsRead(String conversationId, String userId, Instant readAt);

    record CreateResult(Message message, boolean created) {
    }

    List<Message> retrieveMsgs(String conversationId);

    List<Message> retrieveMsgs(String conversationId, int limit);

    List<Message> retrieveMsgsBefore(String conversationId, String beforeMessageId, int limit);

    CreateResult saveMsg(String content, String conversationId, String senderId);
}
