package com.gobison.backend.features.livechat.domain.repository;

import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;

import java.util.List;

public interface MessageRepository {
    public Message retrieveLatestMsg(String conversationId);

    long countUnreadMessages(String conversationId, String userId);

    record CreateResult(Message message, boolean created) {
    }

    public List<Message> retrieveMsgs(String conversationId);

    public CreateResult saveMsg(String content, String conversationId, String senderId);
}
