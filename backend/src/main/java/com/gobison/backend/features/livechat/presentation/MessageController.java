package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.application.GetMessagesService;
import com.gobison.backend.features.livechat.application.dto.RetrieveMessage;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/conversations")
public class MessageController {
    private static final int DEFAULT_MESSAGE_LIMIT = 50;

    private final UserRepository userRepository;
    private final GetMessagesService getMessagesService;

    public MessageController(UserRepository userRepository, GetMessagesService getMessagesService) {
        this.userRepository = userRepository;
        this.getMessagesService = getMessagesService;
    }

    @GetMapping("/{conversationId}/messages")
    public ResponseEntity<RetrieveMessage> getMessages(
            @PathVariable String conversationId,
            @RequestParam(defaultValue = "" + DEFAULT_MESSAGE_LIMIT) int limit,
            @RequestParam(required = false) String before,
            Authentication authentication) {
        var user = userRepository.findByEmail(authentication.getName())
                    .orElseThrow(() -> new GetMessagesException(GetMessagesException.Reason.USER_NOT_FOUND));
        return ResponseEntity.ok(getMessagesService.getConversation(user, conversationId, limit, before));
    }
}
