package com.gobison.backend.features.livechat.domain.repository;

import com.gobison.backend.features.livechat.domain.model.Conversation;

public interface ConversationRepository {

    CreateResult createOrFindDirectConversation(String firstParticipantId, String secondParticipantId);

    record CreateResult(Conversation conversation, boolean created) {
    }

    Conversation create(Conversation conversation);
}