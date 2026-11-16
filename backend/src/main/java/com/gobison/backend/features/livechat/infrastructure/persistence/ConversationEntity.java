package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Conversation;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.util.List;

@Entity
@Table(
        name = "conversations",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_conversations_direct_participants",
                columnNames = {"direct_participant_one_id", "direct_participant_two_id"}))
public class ConversationEntity {

    @Id
    @Column(name = "conversation_id", nullable = false, length = 41)
    private String id;

    @Column(name = "direct_participant_one_id", nullable = false, length = 254)
    private String directParticipantOneId;

    @Column(name = "direct_participant_two_id", nullable = false, length = 254)
    private String directParticipantTwoId;

    protected ConversationEntity() {
    }

    public ConversationEntity(Conversation conversation) {
        id = conversation.getId();
        var participants = conversation.getParticipants();
        directParticipantOneId = participants.get(0);
        directParticipantTwoId = participants.get(1);
    }

    public Conversation toDomain() {
        return new Conversation(id, List.of(directParticipantOneId, directParticipantTwoId));
    }
}
