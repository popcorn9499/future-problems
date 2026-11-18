package com.gobison.backend.features.livechat.application;

import com.gobison.backend.features.livechat.application.dto.ConversationSummaryResponse;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
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
        List<ConversationSummaryResponse> convoSummaryList = new ArrayList<>();
        List<Conversation> convoList = conversationRepository.findConversations(user.getEmail());

        for (Conversation conversation : convoList) {
            ConversationSummaryResponse.Participant otherPerson =
                    getParticipant(conversation.getParticipants(), user);
            Message latestMessage = messageRepository.retrieveLatestMsg(conversation.getId());
            long unreadCount = messageRepository.countUnreadMessages(conversation.getId(), user.getEmail());

            convoSummaryList.add(new ConversationSummaryResponse(
                    conversation.getId(),
                    otherPerson,
                    latestMessage == null ? null : latestMessage.getContent(),
                    latestMessage == null ? null : latestMessage.getSentAt(),
                    unreadCount));
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
