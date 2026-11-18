package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.application.CreateConversationException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/conversation")
public class CreateConversationController {

    private final CreateConversationService createConversationService;

    public CreateConversationController(CreateConversationService createConversationService) {
        this.createConversationService = createConversationService;
    }

    public record CreateConversationRequest(@NotBlank @Email String participantId) {
    }

    public record CreateConversationResponse(String conversationId, List<String> participants, Instant createdAt) {
    }

    @PostMapping
    public ResponseEntity<CreateConversationResponse> create(
            Authentication authentication,
            @Valid @RequestBody CreateConversationRequest request) {
        var result = createConversationService.create(authentication.getName(), request.participantId());
        if (!result.created()) {
            throw new CreateConversationException(
                    CreateConversationException.Reason.CONVERSATION_ALREADY_EXISTS);
        }

        var conversation = result.conversation();
        var response = new CreateConversationResponse(
                conversation.getId(), conversation.getParticipants(), conversation.getCreatedAt());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
