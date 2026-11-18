package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.application.CreateConversationException;
import com.gobison.backend.features.livechat.application.GetConversationsService;
import com.gobison.backend.features.livechat.application.dto.ConversationSummaryResponse;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/conversation")
public class ConversationController {

    private final UserRepository userRepository;
    private final CreateConversationService createConversationService;
    private final GetConversationsService getConversationsService;

    public ConversationController(CreateConversationService createConversationService,
                                  UserRepository userRepository,
                                  GetConversationsService getConversationsService
                                    ) {
        this.createConversationService = createConversationService;
        this.userRepository = userRepository;
        this.getConversationsService = getConversationsService;
    }

    public record CreateConversationRequest(@NotBlank @Email String participantId) {
    }

    public record CreateConversationResponse(String conversationId, List<String> participants, Instant createdAt) {
    }

    public record GetConversationsResponse(List<ConversationSummaryResponse> conversations) {
    }

    @PostMapping
    public ResponseEntity<CreateConversationResponse> create(
            Authentication authentication,
            @Valid @RequestBody CreateConversationRequest request) {
        var user = userRepository.findByEmail(authentication.getName()).orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        var result = createConversationService.create(user.getEmail(), request.participantId());
        if (!result.created()) {
            throw new CreateConversationException(
                    CreateConversationException.Reason.CONVERSATION_ALREADY_EXISTS);
        }

        var conversation = result.conversation();
        var response = new CreateConversationResponse(
                conversation.getId(), conversation.getParticipants(), conversation.getCreatedAt());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }


    @GetMapping
    public ResponseEntity<GetConversationsResponse> getConversations(Authentication authentication) {
        var user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        var conversations = getConversationsService.getConversations(user);
        return ResponseEntity.ok(new GetConversationsResponse(conversations));
    }
}
