package com.gobison.backend.features.livechat.domain.repository;

import com.gobison.backend.features.livechat.domain.model.Message;

import java.util.List;

public interface MessageRepository {
    public Message retrieveLatestMsg(String conversationId);

    public List<Message> retrieveMsgs(String conversationId);

    public void saveMsg(Message msg);
}
