package com.gobison.backend.features.livechat.application.dto;

import java.util.List;

public record RetrieveMessage(
        String conversationId,
        List<MessageItem> messages,
        Pagination pagination
) {
    public record Pagination(
            int limit,
            boolean hasMore,
            String nextCursor
    ) {
    }
}
