package com.gobison.backend.features.livechat.application.dto;

import java.time.Instant;
import java.util.List;

public record MarkMessagesReadResponse(
        String conversationId,
        int markedAsRead,
        List<String> messageIds,
        Instant readAt
) {
}
