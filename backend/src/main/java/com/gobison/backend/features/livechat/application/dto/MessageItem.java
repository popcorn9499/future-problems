package com.gobison.backend.features.livechat.application.dto;

import java.time.Instant;

public record MessageItem(
        String messageId,
        String senderId,
        String content,
        Instant sentAt,
        Instant readAt
) {
}
