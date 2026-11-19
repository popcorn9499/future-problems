package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.GetMessagesService;
import com.gobison.backend.features.livechat.application.dto.RetrieveMessage;
import com.gobison.backend.features.livechat.presentation.MessageController;
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
    void retrievesMessagesForAuthenticatedUserWithLimitAndCursor() {
        var userRepository = mock(UserRepository.class);
        var getMessagesService = mock(GetMessagesService.class);
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
        var controller = new MessageController(userRepository, getMessagesService);

        var response = controller.getMessages("conv_123", 25, "msg_002", authentication);

        assertEquals(200, response.getStatusCode().value());
        assertEquals(responseBody, response.getBody());
        verify(getMessagesService).getConversation(user, "conv_123", 25, "msg_002");
    }
}
