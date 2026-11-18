package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.stereotype.Service;

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
        if (participantId == null || participantId.isBlank()) {
            throw new CreateConversationException(CreateConversationException.Reason.INVALID_REQUEST);
        }

        var currentUser = userRepository.findByEmail(currentUserId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new CreateConversationException(
                        CreateConversationException.Reason.CURRENT_USER_NOT_FOUND));

        String normalizedParticipantId = participantId.trim().toLowerCase(Locale.ROOT);
        if (currentUser.getEmail().equalsIgnoreCase(normalizedParticipantId)) {
            throw new CreateConversationException(CreateConversationException.Reason.SELF_CONVERSATION);
        }

        userRepository.findByEmail(normalizedParticipantId)
                .filter(user -> !user.isDeleted())
                .orElseThrow(() -> new CreateConversationException(
                        CreateConversationException.Reason.PARTICIPANT_NOT_FOUND));

        return conversationRepository.createOrFindDirectConversation(
                currentUser.getEmail(), normalizedParticipantId);
    }
}
