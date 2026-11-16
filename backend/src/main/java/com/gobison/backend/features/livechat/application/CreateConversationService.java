package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
public class CreateConversationService {

    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;

    public CreateConversationService(
            UserRepository userRepository,
            ConversationRepository conversationRepository) {
        this.userRepository = userRepository;
        this.conversationRepository = conversationRepository;
    }

    public ConversationRepository.CreateResult create(String currentUserId, String participantId) {
        var currentUser = userRepository.findByEmail(currentUserId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        String normalizedParticipantId = participantId.trim().toLowerCase(Locale.ROOT);
        if (currentUser.getEmail().equalsIgnoreCase(normalizedParticipantId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cannot create a conversation with yourself");
        }

        userRepository.findByEmail(normalizedParticipantId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Participant not found"));

        return conversationRepository.createOrFindDirectConversation(
                currentUser.getEmail(), normalizedParticipantId);
    }
}
