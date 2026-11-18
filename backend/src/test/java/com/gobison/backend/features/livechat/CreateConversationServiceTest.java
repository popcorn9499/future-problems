package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class CreateConversationServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final ConversationRepository conversationRepository = mock(ConversationRepository.class);
    private final CreateConversationService service =
            new CreateConversationService(userRepository, conversationRepository);

    @Test
    void returnsNotFoundWhenCurrentUserDoesNotExist() {
        when(userRepository.findByEmail("first@example.com")).thenReturn(Optional.empty());

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> service.create("first@example.com", "second@example.com")
        );

        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
        verifyNoInteractions(conversationRepository);
    }

    @Test
    void returnsNotFoundWhenParticipantDoesNotExist() {
        when(userRepository.findByEmail("first@example.com"))
                .thenReturn(Optional.of(user("first@example.com")));
        when(userRepository.findByEmail("missing@example.com")).thenReturn(Optional.empty());

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> service.create("first@example.com", "missing@example.com")
        );

        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
        verifyNoInteractions(conversationRepository);
    }

    @Test
    void rejectsBlankParticipantIdAsBadRequest() {
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> service.create("first@example.com", "  ")
        );

        assertEquals(HttpStatus.BAD_REQUEST, exception.getStatusCode());
        verifyNoInteractions(userRepository, conversationRepository);
    }

    @Test
    void rejectsConversationWithSelfAsBadRequest() {
        when(userRepository.findByEmail("first@example.com"))
                .thenReturn(Optional.of(user("first@example.com")));

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> service.create("first@example.com", "FIRST@example.com")
        );

        assertEquals(HttpStatus.BAD_REQUEST, exception.getStatusCode());
        verifyNoInteractions(conversationRepository);
    }

    private static User user(String email) {
        return new User(email, "password-hash", "First", "User", true);
    }
}
