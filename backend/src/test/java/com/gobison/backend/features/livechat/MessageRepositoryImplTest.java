package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.infrastructure.persistence.MessageEntity;
import com.gobison.backend.features.livechat.infrastructure.persistence.MessageRepositoryImpl;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import jakarta.persistence.TypedQuery;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MessageRepositoryImplTest {

    @Test
    void countsUnreadMessagesReceivedByUserInConversation() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<Long> query = mock(TypedQuery.class);
        when(entityManager.createQuery(anyString(), eq(Long.class))).thenReturn(query);
        when(query.setParameter("conversationId", "conv_123")).thenReturn(query);
        when(query.setParameter("userId", "alice@example.com")).thenReturn(query);
        when(query.getSingleResult()).thenReturn(3L);
        var repository = repositoryWith(entityManager);

        long unreadCount = repository.countUnreadMessages("conv_123", "alice@example.com");

        assertEquals(3L, unreadCount);
        verify(entityManager).createQuery(
                argThat(jpql -> jpql.contains("m.conversationId = :conversationId")
                        && jpql.contains("m.senderId <> :userId")
                        && jpql.contains("m.readAt IS NULL")),
                eq(Long.class));
        verify(query).setParameter("conversationId", "conv_123");
        verify(query).setParameter("userId", "alice@example.com");
    }

    @Test
    void retrievesMessagesInSentOrderForConversation() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<MessageEntity> query = mock(TypedQuery.class);
        var first = new MessageEntity(Message.restore(
                "msg_123", "conv_123", "usr_123", "First", Instant.parse("2026-11-10T14:40:00Z"), null));
        var second = new MessageEntity(Message.restore(
                "msg_124", "conv_123", "usr_124", "Second", Instant.parse("2026-11-10T14:45:00Z"), null));
        when(entityManager.createQuery(anyString(), eq(MessageEntity.class))).thenReturn(query);
        when(query.setParameter("conversationId", "conv_123")).thenReturn(query);
        when(query.getResultList()).thenReturn(List.of(first, second));
        var repository = repositoryWith(entityManager);

        var messages = repository.retrieveMsgs("conv_123");

        assertEquals(List.of("msg_123", "msg_124"), messages.stream().map(Message::getMsgId).toList());
        verify(query).setParameter("conversationId", "conv_123");
    }

    @Test
    void retrievesLatestMessageAndLimitsQueryToOneResult() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<MessageEntity> query = mock(TypedQuery.class);
        var latest = new MessageEntity(Message.restore(
                "msg_124", "conv_123", "usr_124", "Latest", Instant.parse("2026-11-10T14:45:00Z"), null));
        when(entityManager.createQuery(anyString(), eq(MessageEntity.class))).thenReturn(query);
        when(query.setParameter("conversationId", "conv_123")).thenReturn(query);
        when(query.setMaxResults(1)).thenReturn(query);
        when(query.getResultList()).thenReturn(List.of(latest));
        var repository = repositoryWith(entityManager);

        var message = repository.retrieveLatestMsg("conv_123");

        assertEquals("msg_124", message.getMsgId());
        verify(query).setMaxResults(1);
    }

    @Test
    void returnsNullWhenConversationHasNoMessages() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<MessageEntity> query = mock(TypedQuery.class);
        when(entityManager.createQuery(anyString(), eq(MessageEntity.class))).thenReturn(query);
        when(query.setParameter("conversationId", "conv_123")).thenReturn(query);
        when(query.setMaxResults(1)).thenReturn(query);
        when(query.getResultList()).thenReturn(List.of());
        var repository = repositoryWith(entityManager);

        assertNull(repository.retrieveLatestMsg("conv_123"));
    }

    @Test
    void insertsMessageAndFindsItByIdReturnedFromDatabase() {
        var entityManager = mock(EntityManager.class);
        var insertQuery = mock(Query.class);
        var savedMessageId = new AtomicReference<String>();
        when(entityManager.createNativeQuery(anyString())).thenReturn(insertQuery);
        when(insertQuery.setParameter(anyString(), any())).thenAnswer(invocation -> {
            if (invocation.<String>getArgument(0).equals("messageId")) {
                savedMessageId.set(invocation.getArgument(1));
            }
            return insertQuery;
        });
        when(insertQuery.getSingleResult()).thenAnswer(invocation -> savedMessageId.get());
        when(entityManager.find(eq(MessageEntity.class), anyString())).thenAnswer(invocation ->
                new MessageEntity(Message.restore(
                        invocation.getArgument(1), "conv_123", "sender@example.com", "Hello",
                        Instant.parse("2026-11-10T14:40:00Z"), null)));
        var repository = repositoryWith(entityManager);

        var result = repository.saveMsg("Hello", "conv_123", "sender@example.com");

        assertTrue(savedMessageId.get().matches("msg_[0-9a-f]{32}"));
        assertEquals(savedMessageId.get(), result.message().getMsgId());
        assertEquals("conv_123", result.message().getConversationId());
        assertEquals("sender@example.com", result.message().getSenderId());
        assertEquals("Hello", result.message().getContent());
        assertNotNull(result.message().getSentAt());
        assertTrue(result.created());
        verify(insertQuery).setParameter("conversationId", "conv_123");
        verify(insertQuery).setParameter("senderId", "sender@example.com");
        verify(insertQuery).setParameter("content", "Hello");
        verify(insertQuery).getSingleResult();
        verify(entityManager).find(MessageEntity.class, savedMessageId.get());
    }

    private MessageRepositoryImpl repositoryWith(EntityManager entityManager) {
        var repository = new MessageRepositoryImpl();
        ReflectionTestUtils.setField(repository, "entityManager", entityManager);
        return repository;
    }
}
