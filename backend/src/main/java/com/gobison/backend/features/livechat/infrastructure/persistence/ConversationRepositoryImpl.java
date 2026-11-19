package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.List;

@Repository
public class ConversationRepositoryImpl implements ConversationRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional
    public Conversation create(Conversation conversation) {
        var entity = new ConversationEntity(conversation);
        entityManager.persist(entity);
        entityManager.flush();
        return entity.toDomain();
    }

    @Override
    @Transactional
    public CreateResult createOrFindDirectConversation(
            String firstParticipantId, String secondParticipantId) {
        //sorts participants so they are always in a consistent order
        String participantOneId = firstParticipantId.compareTo(secondParticipantId) < 0
                ? firstParticipantId : secondParticipantId;
        String participantTwoId = firstParticipantId.compareTo(secondParticipantId) < 0
                ? secondParticipantId : firstParticipantId;
        String candidateId = "conv_" + UUID.randomUUID().toString().replace("-", "");

        // ensures we only add to the database if its unique
        String conversationId = (String) entityManager.createNativeQuery("""
                        INSERT INTO conversations (
                            conversation_id,
                            direct_participant_one_id,
                            direct_participant_two_id
                        )
                        VALUES (:id, :participantOneId, :participantTwoId)
                        ON CONFLICT (direct_participant_one_id, direct_participant_two_id)
                        DO UPDATE SET conversation_id = conversations.conversation_id
                        RETURNING conversation_id
                        """)
                .setParameter("id", candidateId)
                .setParameter("participantOneId", participantOneId)
                .setParameter("participantTwoId", participantTwoId)
                .getSingleResult();

        var entity = entityManager.find(ConversationEntity.class, conversationId);
        return new CreateResult(entity.toDomain(), candidateId.equals(conversationId));
    }

    @Override
    public List<Conversation> findConversations(String participantId) {
        String jpql = """
                    SELECT c FROM ConversationEntity c
                    WHERE c.directParticipantOneId = :userId 
                       OR c.directParticipantTwoId = :userId
                """;

        List<ConversationEntity> entities = entityManager.createQuery(jpql, ConversationEntity.class)
                .setParameter("userId", participantId)
                .getResultList();

        return entities.stream()
                .map(ConversationEntity::toDomain)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsConversation(String conversationId) {
        return entityManager.createQuery(
                        "SELECT COUNT(c) FROM ConversationEntity c WHERE c.id = :conversationId",
                        Long.class)
                .setParameter("conversationId", conversationId)
                .getSingleResult() > 0;
    }
}
