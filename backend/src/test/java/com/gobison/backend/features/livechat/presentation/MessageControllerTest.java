package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.GetMessagesService;
import com.gobison.backend.features.livechat.application.GetConversationsService;
import com.gobison.backend.features.livechat.application.MarkMessagesReadService;
import com.gobison.backend.features.livechat.application.SendMessageService;
import com.gobison.backend.features.livechat.application.dto.ConversationSummaryResponse;
import com.gobison.backend.features.livechat.application.dto.MarkMessagesReadResponse;
import com.gobison.backend.features.livechat.application.dto.RetrieveMessage;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.presentation.MessageController;
import com.gobison.backend.features.livechat.application.dto.SendMessageResponse;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class MessageControllerTest {

    @Test
    void retrievesConversationsForAuthenticatedUser() {
        var userRepository = mock(UserRepository.class);
        var getMessagesService = mock(GetMessagesService.class);
        var sendMessageService = mock(SendMessageService.class);
        var markMessagesReadService = mock(MarkMessagesReadService.class);
        var getConversationsService = mock(GetConversationsService.class);
        var authentication = mock(Authentication.class);
        var user = new User("first@example.com", "password", "First", "User", true);
        var conversations = List.of(new ConversationSummaryResponse(
                "conv_123",
                new ConversationSummaryResponse.Participant("second@example.com", "Second", "User", "#123ABC"),
                "Hello",
                java.time.Instant.parse("2026-11-10T14:40:00Z"),
                2L));
        when(authentication.getName()).thenReturn("first@example.com");
        when(userRepository.findByEmail("first@example.com")).thenReturn(Optional.of(user));
        when(getConversationsService.getConversations(user)).thenReturn(conversations);
        var controller = new MessageController(
                userRepository, getMessagesService, sendMessageService,
                markMessagesReadService, getConversationsService);

        var response = controller.getConversations(authentication);

        assertEquals(200, response.getStatusCode().value());
        assertEquals(conversations, response.getBody().conversations());
        verify(getConversationsService).getConversations(user);
    }

    @Test
    void retrievesMessagesForAuthenticatedUserWithLimitAndCursor() {
        var userRepository = mock(UserRepository.class);
        var getMessagesService = mock(GetMessagesService.class);
        var sendMessageService = mock(SendMessageService.class);
        var markMessagesReadService = mock(MarkMessagesReadService.class);
        var getConversationsService = mock(GetConversationsService.class);
        var authentication = mock(Authentication.class);
        var user = new User("first@example.com", "password", "First", "User", true);
        var responseBody = new RetrieveMessage(
                "conv_123",
                List.of(),
                new RetrieveMessage.Pagination(25, true, "msg_001"));
        when(authentication.getName()).thenReturn("first@example.com");
        when(userRepository.findByEmail("first@example.com")).thenReturn(Optional.of(user));
        when(getMessagesService.getConversation(user, "conv_123", 25, "msg_002"))
                .thenReturn(responseBody);
        var controller = new MessageController(
                userRepository, getMessagesService, sendMessageService,
                markMessagesReadService, getConversationsService);

        var response = controller.getMessages("conv_123", 25, "msg_002", authentication);

        assertEquals(200, response.getStatusCode().value());
        assertEquals(responseBody, response.getBody());
        verify(getMessagesService).getConversation(user, "conv_123", 25, "msg_002");
    }

    @Test
    void createsMessageForAuthenticatedUser() {
        var userRepository = mock(UserRepository.class);
        var getMessagesService = mock(GetMessagesService.class);
        var sendMessageService = mock(SendMessageService.class);
        var markMessagesReadService = mock(MarkMessagesReadService.class);
        var getConversationsService = mock(GetConversationsService.class);
        var authentication = mock(Authentication.class);
        var user = new User("first@example.com", "password", "First", "User", true);
        var message = Message.restore(
                "msg_124",
                "conv_123",
                "first@example.com",
                "Are you available on Monday?",
                java.time.Instant.parse("2026-11-10T14:40:00Z"),
                null);
        when(authentication.getName()).thenReturn("first@example.com");
        when(userRepository.findByEmail("first@example.com")).thenReturn(Optional.of(user));
        when(sendMessageService.send(user, "conv_123", "Are you available on Monday?"))
                .thenReturn(message);
        var controller = new MessageController(
                userRepository, getMessagesService, sendMessageService,
                markMessagesReadService, getConversationsService);

        var response = controller.sendMessage(
                "conv_123",
                new MessageController.SendMessageRequest("Are you available on Monday?"),
                authentication);

        assertEquals(201, response.getStatusCode().value());
        assertEquals(
                new SendMessageResponse(
                        "msg_124",
                        "conv_123",
                        "first@example.com",
                        "Are you available on Monday?",
                        message.getSentAt(),
                        null),
                response.getBody());
        verify(sendMessageService).send(user, "conv_123", "Are you available on Monday?");
    }

    @Test
    void marksConversationMessagesAsReadForAuthenticatedUser() {
        var userRepository = mock(UserRepository.class);
        var getMessagesService = mock(GetMessagesService.class);
        var sendMessageService = mock(SendMessageService.class);
        var markMessagesReadService = mock(MarkMessagesReadService.class);
        var getConversationsService = mock(GetConversationsService.class);
        var authentication = mock(Authentication.class);
        var user = new User("first@example.com", "password", "First", "User", true);
        var responseBody = new MarkMessagesReadResponse(
                "conv_123", 2, List.of("msg_001", "msg_002"), java.time.Instant.parse("2026-11-10T14:45:00Z"));
        when(authentication.getName()).thenReturn("first@example.com");
        when(userRepository.findByEmail("first@example.com")).thenReturn(Optional.of(user));
        when(markMessagesReadService.markRead(user, "conv_123")).thenReturn(responseBody);
        var controller = new MessageController(
                userRepository, getMessagesService, sendMessageService,
                markMessagesReadService, getConversationsService);

        var response = controller.markMessagesRead("conv_123", authentication);

        assertEquals(200, response.getStatusCode().value());
        assertEquals(responseBody, response.getBody());
        verify(markMessagesReadService).markRead(user, "conv_123");
    }
}
