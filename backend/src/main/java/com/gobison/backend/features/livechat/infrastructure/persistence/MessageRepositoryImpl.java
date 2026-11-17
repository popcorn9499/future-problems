package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public class MessageRepositoryImpl implements MessageRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional(readOnly = true)
    public Message retrieveLatestMsg(String conversationId) {
        List<MessageEntity> entities = entityManager.createQuery(
                        "SELECT m FROM MessageEntity m WHERE m.conversationId = :conversationId "
                                + "ORDER BY m.sentAt DESC, m.msgId DESC",
                        MessageEntity.class)
                .setParameter("conversationId", conversationId)
                .setMaxResults(1)
                .getResultList();

        return entities.isEmpty() ? null : entities.getFirst().toDomain();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Message> retrieveMsgs(String conversationId) {
        return entityManager.createQuery(
                        "SELECT m FROM MessageEntity m WHERE m.conversationId = :conversationId "
                                + "ORDER BY m.sentAt ASC, m.msgId ASC",
                        MessageEntity.class)
                .setParameter("conversationId", conversationId)
                .getResultList()
                .stream()
                .map(MessageEntity::toDomain)
                .toList();
    }

    @Override
    @Transactional
    public void saveMsg(Message msg) {
        entityManager.persist(new MessageEntity(msg));
    }
}
