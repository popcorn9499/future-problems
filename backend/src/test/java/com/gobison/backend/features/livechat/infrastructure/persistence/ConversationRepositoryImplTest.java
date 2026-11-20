package com.gobison.backend.features.livechat.infrastructure.persistence;

import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.infrastructure.persistence.ConversationEntity;
import com.gobison.backend.features.livechat.infrastructure.persistence.ConversationRepositoryImpl;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ConversationRepositoryImplTest {

    @Test
    void findsAndMapsConversationsForEitherParticipantColumn() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<ConversationEntity> query = mock(TypedQuery.class);
        var firstConversation = new ConversationEntity(
                new Conversation("conv_123", List.of("alice@example.com", "bob@example.com")));
        var secondConversation = new ConversationEntity(
                new Conversation("conv_456", List.of("carol@example.com", "alice@example.com")));
        when(entityManager.createQuery(anyString(), eq(ConversationEntity.class))).thenReturn(query);
        when(query.setParameter("userId", "alice@example.com")).thenReturn(query);
        when(query.getResultList()).thenReturn(List.of(firstConversation, secondConversation));
        var repository = new ConversationRepositoryImpl();
        ReflectionTestUtils.setField(repository, "entityManager", entityManager);

        var conversations = repository.findConversations("alice@example.com");

        assertEquals(2, conversations.size());
        assertEquals(
                List.of("alice@example.com", "bob@example.com"),
                conversations.get(0).getParticipants());
        assertEquals("conv_123", conversations.get(0).getId());
        assertEquals(
                List.of("alice@example.com", "carol@example.com"),
                conversations.get(1).getParticipants());
        assertEquals("conv_456", conversations.get(1).getId());
        verify(entityManager).createQuery(
                argThat(jpql -> jpql.contains("c.directParticipantOneId = :userId")
                        && jpql.contains("c.directParticipantTwoId = :userId")),
                eq(ConversationEntity.class));
        verify(query).setParameter("userId", "alice@example.com");
    }

    @Test
    void returnsEmptyListWhenParticipantHasNoConversations() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<ConversationEntity> query = mock(TypedQuery.class);
        when(entityManager.createQuery(anyString(), eq(ConversationEntity.class))).thenReturn(query);
        when(query.setParameter("userId", "alice@example.com")).thenReturn(query);
        when(query.getResultList()).thenReturn(List.of());
        var repository = new ConversationRepositoryImpl();
        ReflectionTestUtils.setField(repository, "entityManager", entityManager);

        var conversations = repository.findConversations("alice@example.com");

        assertEquals(List.of(), conversations);
        verify(query).setParameter("userId", "alice@example.com");
    }

    @Test
    void checksWhetherConversationExists() {
        var entityManager = mock(EntityManager.class);
        @SuppressWarnings("unchecked")
        TypedQuery<Long> query = mock(TypedQuery.class);
        when(entityManager.createQuery(anyString(), eq(Long.class))).thenReturn(query);
        when(query.setParameter("conversationId", "conv_123")).thenReturn(query);
        when(query.getSingleResult()).thenReturn(1L);
        var repository = new ConversationRepositoryImpl();
        ReflectionTestUtils.setField(repository, "entityManager", entityManager);

        assertTrue(repository.existsConversation("conv_123"));
        verify(query).setParameter("conversationId", "conv_123");
    }
}
