package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.application.GetMessagesService;
import com.gobison.backend.features.livechat.application.MarkMessagesReadException;
import com.gobison.backend.features.livechat.application.MarkMessagesReadService;
import com.gobison.backend.features.livechat.application.SendMessageService;
import com.gobison.backend.features.livechat.application.dto.MarkMessagesReadResponse;
import com.gobison.backend.features.livechat.application.dto.RetrieveMessage;
import com.gobison.backend.features.livechat.application.dto.SendMessageResponse;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/conversations")
public class MessageController {
    private static final int DEFAULT_MESSAGE_LIMIT = 50;

    private final UserRepository userRepository;
    private final GetMessagesService getMessagesService;
    private final SendMessageService sendMessageService;
    private final MarkMessagesReadService markMessagesReadService;

    public MessageController(
            UserRepository userRepository,
            GetMessagesService getMessagesService,
            SendMessageService sendMessageService,
            MarkMessagesReadService markMessagesReadService) {
        this.userRepository = userRepository;
        this.getMessagesService = getMessagesService;
        this.sendMessageService = sendMessageService;
        this.markMessagesReadService = markMessagesReadService;
    }

    public record SendMessageRequest(String content) {
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

    @PostMapping("/{conversationId}/messages")
    public ResponseEntity<SendMessageResponse> sendMessage(
            @PathVariable String conversationId,
            @RequestBody SendMessageRequest request,
            Authentication authentication) {
        var user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new GetMessagesException(GetMessagesException.Reason.USER_NOT_FOUND));
        var message = sendMessageService.send(user, conversationId, request.content());
        return ResponseEntity.status(HttpStatus.CREATED).body(SendMessageResponse.from(message));
    }

    @PatchMapping("/{conversationId}/read")
    public ResponseEntity<MarkMessagesReadResponse> markMessagesRead(
            @PathVariable String conversationId,
            Authentication authentication) {
        var user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new MarkMessagesReadException(MarkMessagesReadException.Reason.USER_NOT_FOUND));
        return ResponseEntity.ok(markMessagesReadService.markRead(user, conversationId));
    }
}
