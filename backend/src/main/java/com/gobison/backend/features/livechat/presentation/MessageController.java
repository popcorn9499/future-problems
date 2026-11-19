package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.application.GetConversationsService;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/conversations")
public class MessageController {
    private final UserRepository userRepository;
    private final CreateConversationService createConversationService;
    private final GetConversationsService getConversationsService;
    private final MessageRepository messageRepository;
    private final ConversationRepository conversationRepository;
    public MessageController(CreateConversationService createConversationService,
                                  UserRepository userRepository,
                                  GetConversationsService getConversationsService,
                             MessageRepository messageRepository,
                             ConversationRepository conversationRepository
    ) {
        this.createConversationService = createConversationService;
        this.userRepository = userRepository;
        this.getConversationsService = getConversationsService;
        this.messageRepository = messageRepository;
        this.conversationRepository = conversationRepository;
    }



    @GetMapping("/{conversationId}/messages")
    public ResponseEntity<List<Message>> getMessages(
            @PathVariable String conversationId,
            Authentication authentication) {
        boolean isParticipant = conversationRepository.findConversations(authentication.getName()).stream()
                .anyMatch(conversation -> conversation.getId().equals(conversationId));
        if (!isParticipant) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
        return ResponseEntity.ok(messageRepository.retrieveMsgs(conversationId));
    }
}
