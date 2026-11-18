package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.application.CreateConversationException;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.presentation.ConversationController;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ConversationControllerTest {

    @Test
    void throwsExceptionWhenConversationAlreadyExists() {
        var service = mock(CreateConversationService.class);
        var userRepository = mock(UserRepository.class);
        var authentication = mock(Authentication.class);
        when(userRepository.findByEmail("first@example.com"))
                .thenReturn(Optional.of(new User("first@example.com", "password", "First", "User", true)));
        when(authentication.getName()).thenReturn("first@example.com");
        when(service.create("first@example.com", "second@example.com"))
                .thenReturn(new ConversationRepository.CreateResult(
                        new Conversation("conv_123", List.of("first@example.com", "second@example.com")),
                        false));
        var controller = new ConversationController(service, userRepository);

        var exception = assertThrows(
                CreateConversationException.class,
                () -> controller.create(
                        authentication, new ConversationController.CreateConversationRequest("second@example.com")));

        assertEquals(CreateConversationException.Reason.CONVERSATION_ALREADY_EXISTS, exception.getReason());
    }

    @Test
    void returnsCreatedWithConversationWhenNewConversationIsCreated() {
        var service = mock(CreateConversationService.class);
        var userRepository = mock(UserRepository.class);
        var authentication = mock(Authentication.class);
        when(userRepository.findByEmail("first@example.com"))
                .thenReturn(Optional.of(new User("first@example.com", "password", "First", "User", true)));
        when(authentication.getName()).thenReturn("first@example.com");
        when(service.create("first@example.com", "second@example.com"))
                .thenReturn(new ConversationRepository.CreateResult(
                        new Conversation("conv_123", List.of("first@example.com", "second@example.com")),
                        true));
        var controller = new ConversationController(service, userRepository);

        var response = controller.create(
                authentication, new ConversationController.CreateConversationRequest("second@example.com"));

        assertEquals(201, response.getStatusCode().value());
        assertEquals("conv_123", response.getBody().conversationId());
        assertEquals(List.of("first@example.com", "second@example.com"), response.getBody().participants());
        assertNotNull(response.getBody().createdAt());
    }
}
