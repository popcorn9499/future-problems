package com.gobison.backend.features.livechat.domain.repository;

import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;

import java.util.List;

public interface MessageRepository {
    public Message retrieveLatestMsg(String conversationId);

    boolean existsMessage(String conversationId, String messageId);

    long countUnreadMessages(String conversationId, String userId);

    record CreateResult(Message message, boolean created) {
    }

    public List<Message> retrieveMsgs(String conversationId);

    List<Message> retrieveMsgs(String conversationId, int limit);

    List<Message> retrieveMsgsBefore(String conversationId, String beforeMessageId, int limit);

    public CreateResult saveMsg(String content, String conversationId, String senderId);
}
