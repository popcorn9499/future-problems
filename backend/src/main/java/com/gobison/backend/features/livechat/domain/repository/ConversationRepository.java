package com.gobison.backend.features.livechat.domain.repository;

import com.gobison.backend.features.livechat.domain.model.Conversation;

import java.util.List;

public interface ConversationRepository {

    CreateResult createOrFindDirectConversation(String firstParticipantId, String secondParticipantId);

    record CreateResult(Conversation conversation, boolean created) {
    }

    Conversation create(Conversation conversation);

    List<Conversation> findConversations(String participantID);

    boolean existsConversation(String conversationId);
}