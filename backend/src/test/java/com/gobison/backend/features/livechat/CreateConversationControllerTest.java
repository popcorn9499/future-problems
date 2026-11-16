package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.presentation.CreateConversationController;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.Authentication;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CreateConversationControllerTest {

    @Test
    void returnsConflictWithoutConversationBodyWhenConversationAlreadyExists() {
        var service = mock(CreateConversationService.class);
        var authentication = mock(Authentication.class);
        when(authentication.getName()).thenReturn("first@example.com");
        when(service.create("first@example.com", "second@example.com"))
                .thenReturn(new ConversationRepository.CreateResult(
                        new Conversation("conv_123", List.of("first@example.com", "second@example.com")),
                        false));
        var controller = new CreateConversationController(service);

        var response = controller.create(
                authentication, new CreateConversationController.CreateConversationRequest("second@example.com"));

        assertEquals(409, response.getStatusCode().value());
        assertNull(response.getBody());
    }

    @Test
    void returnsCreatedWithConversationWhenNewConversationIsCreated() {
        var service = mock(CreateConversationService.class);
        var authentication = mock(Authentication.class);
        when(authentication.getName()).thenReturn("first@example.com");
        when(service.create("first@example.com", "second@example.com"))
                .thenReturn(new ConversationRepository.CreateResult(
                        new Conversation("conv_123", List.of("first@example.com", "second@example.com")),
                        true));
        var controller = new CreateConversationController(service);

        var response = controller.create(
                authentication, new CreateConversationController.CreateConversationRequest("second@example.com"));

        assertEquals(201, response.getStatusCode().value());
        assertEquals("conv_123", response.getBody().conversationId());
    }
}
