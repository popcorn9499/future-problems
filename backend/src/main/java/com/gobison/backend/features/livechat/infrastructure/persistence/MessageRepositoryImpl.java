package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.domain.repository.MessageRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

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
    public boolean existsMessage(String conversationId, String messageId) {
        return entityManager.createQuery(
                        "SELECT COUNT(m) FROM MessageEntity m "
                                + "WHERE m.conversationId = :conversationId AND m.msgId = :messageId",
                        Long.class)
                .setParameter("conversationId", conversationId)
                .setParameter("messageId", messageId)
                .getSingleResult() > 0;
    }

    @Override
    @Transactional(readOnly = true)
    public long countUnreadMessages(String conversationId, String userId) {
        return entityManager.createQuery("""
                        SELECT COUNT(m) FROM MessageEntity m
                        WHERE m.conversationId = :conversationId
                          AND m.senderId <> :userId
                          AND m.readAt IS NULL
                        """, Long.class)
                .setParameter("conversationId", conversationId)
                .setParameter("userId", userId)
                .getSingleResult();
    }

    @Override
    @Transactional
    public List<String> markUnreadMessagesAsRead(String conversationId, String userId, Instant readAt) {
        return entityManager.createNativeQuery("""
                        UPDATE messages
                        SET read_at = :readAt
                        WHERE conversation_id = :conversationId
                          AND sender_id <> :userId
                          AND read_at IS NULL
                        RETURNING message_id
                        """)
                .setParameter("readAt", readAt)
                .setParameter("conversationId", conversationId)
                .setParameter("userId", userId)
                .getResultList()
                .stream()
                .map(Object::toString)
                .toList();
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
    @Transactional(readOnly = true)
    public List<Message> retrieveMsgs(String conversationId, int limit) {
        List<Message> messages = new ArrayList<>(entityManager.createQuery(
                        "SELECT m FROM MessageEntity m WHERE m.conversationId = :conversationId "
                                + "ORDER BY m.sentAt DESC, m.msgId DESC",
                        MessageEntity.class)
                .setParameter("conversationId", conversationId)
                .setMaxResults(limit)
                .getResultList()
                .stream()
                .map(MessageEntity::toDomain)
                .toList());

        Collections.reverse(messages);
        return List.copyOf(messages);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Message> retrieveMsgsBefore(String conversationId, String beforeMessageId, int limit) {
        List<Message> messages = new ArrayList<>(entityManager.createQuery(
                        "SELECT m FROM MessageEntity m WHERE m.conversationId = :conversationId "
                                + "AND EXISTS (SELECT boundary FROM MessageEntity boundary "
                                + "WHERE boundary.conversationId = :conversationId "
                                + "AND boundary.msgId = :beforeMessageId "
                                + "AND (m.sentAt < boundary.sentAt "
                                + "OR (m.sentAt = boundary.sentAt AND m.msgId < boundary.msgId))) "
                                + "ORDER BY m.sentAt DESC, m.msgId DESC",
                        MessageEntity.class)
                .setParameter("conversationId", conversationId)
                .setParameter("beforeMessageId", beforeMessageId)
                .setMaxResults(limit)
                .getResultList()
                .stream()
                .map(MessageEntity::toDomain)
                .toList());

        Collections.reverse(messages);
        return List.copyOf(messages);
    }

    @Override
    @Transactional
    public CreateResult saveMsg(String content, String conversationId, String senderId) {
        String candidateId = "msg_" + UUID.randomUUID().toString().replace("-", "");

        Message message = new Message(candidateId, conversationId, senderId, content);
        String messageId = (String) entityManager.createNativeQuery("""
                        INSERT INTO messages (
                            message_id,
                            conversation_id,
                            sender_id,
                            content,
                            sent_at
                        )
                        VALUES (:messageId, :conversationId, :senderId, :content, :sentAt)
                        RETURNING message_id
                        """)
                .setParameter("messageId", candidateId)
                .setParameter("conversationId", conversationId)
                .setParameter("senderId", senderId)
                .setParameter("content", content)
                .setParameter("sentAt", message.getSentAt())
                .getSingleResult();

        var entity = entityManager.find(MessageEntity.class, messageId);
        return new CreateResult(entity.toDomain(), true);
    }
}
