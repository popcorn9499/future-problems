package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.infrastructure.persistence.MessageEntity;
import com.gobison.backend.features.livechat.infrastructure.persistence.MessageRepositoryImpl;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MessageRepositoryImplTest {

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
    void savesMessageEntity() {
        var entityManager = mock(EntityManager.class);
        var repository = repositoryWith(entityManager);
        var message = new Message("msg_123", "conv_123", "usr_123", "Hello");

        repository.saveMsg(message);

        verify(entityManager).persist(any(MessageEntity.class));
    }

    private MessageRepositoryImpl repositoryWith(EntityManager entityManager) {
        var repository = new MessageRepositoryImpl();
        ReflectionTestUtils.setField(repository, "entityManager", entityManager);
        return repository;
    }
}
