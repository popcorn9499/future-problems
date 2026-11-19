package com.gobison.backend.features.livechat.application.dto;

import com.gobison.backend.features.livechat.domain.model.Message;

import java.time.Instant;

public record SendMessageResponse(
        String messageId,
        String conversationId,
        String senderId,
        String content,
        Instant sentAt,
        Instant readAt
) {
    public static SendMessageResponse from(Message message) {
        return new SendMessageResponse(
                message.getMsgId(),
                message.getConversationId(),
                message.getSenderId(),
                message.getContent(),
                message.getSentAt(),
                message.getReadAt());
    }
}
