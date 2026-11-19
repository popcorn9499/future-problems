package com.gobison.backend.features.livechat.application.dto;

import java.time.Instant;

public record ConversationSummaryResponse(
        String conversationId,
        Participant participant,
        String lastMessage,
        Instant lastMessageAt,
        long unreadCount
) {
    public record Participant(
            String userId,
            String firstName,
            String lastName,
            String avatarColor
    ) {
    }
}
