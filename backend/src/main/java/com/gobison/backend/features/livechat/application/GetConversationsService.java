package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.application.dto.ConversationSummaryResponse;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;

import java.util.ArrayList;
import java.util.List;

public class GetConversationsService {
    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;

    public GetConversationsService(
            UserRepository userRepository,
            ConversationRepository conversationRepository,
            MessageRepository messageRepository) {
        this.userRepository = userRepository;
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
    }

    public List<ConversationSummaryResponse> getConversations(User user) {
        List<ConversationSummaryResponse> convoSummaryList = new ArrayList<ConversationSummaryResponse>();

        List<Conversation> convoList = conversationRepository.findConversations(user.getEmail());
        ConversationSummaryResponse convoSumResp;
        ConversationSummaryResponse.Participant otherPerson;

        Message msg;
        int unreadCount = 0; // TODO implement

        for (Conversation conversation : convoList) {
            // Build a summary response for this conversation.
            otherPerson = getParticipant(conversation.getParticipants(), user);
            msg = messageRepository.retrieveLatestMsg(conversation.getId());
            convoSumResp = new ConversationSummaryResponse(conversation.getId(), otherPerson, msg.getContent(), msg.getSentAt(), unreadCount);

        }

        return convoSummaryList;
    }

    public ConversationSummaryResponse.Participant getParticipant(List<String> participants, User me) {
        String otherParticipantId = participants.stream()
                .filter(participantId -> !participantId.equals(me.getEmail()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Conversation does not contain another participant"));

        User otherUser = userRepository.findByEmail(otherParticipantId)
                .orElseThrow(() -> new IllegalStateException(
                        "Conversation participant not found: " + otherParticipantId));

        return new ConversationSummaryResponse.Participant(
                otherUser.getEmail(),
                otherUser.getFirstName(),
                otherUser.getLastName(),
                otherUser.getAvatarColor());
    }
}
