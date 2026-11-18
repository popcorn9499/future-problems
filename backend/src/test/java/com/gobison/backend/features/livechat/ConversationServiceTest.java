package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.application.CreateConversationException;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class ConversationServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final ConversationRepository conversationRepository = mock(ConversationRepository.class);
    private final CreateConversationService service =
            new CreateConversationService(userRepository, conversationRepository);

    @Test
    void throwsCurrentUserNotFoundWhenCurrentUserDoesNotExist() {
        when(userRepository.findByEmail("first@example.com")).thenReturn(Optional.empty());

        CreateConversationException exception = assertThrows(
                CreateConversationException.class,
                () -> service.create("first@example.com", "second@example.com")
        );

        assertEquals(CreateConversationException.Reason.CURRENT_USER_NOT_FOUND, exception.getReason());
        verifyNoInteractions(conversationRepository);
    }

    @Test
    void throwsParticipantNotFoundWhenParticipantDoesNotExist() {
        when(userRepository.findByEmail("first@example.com"))
                .thenReturn(Optional.of(user("first@example.com")));
        when(userRepository.findByEmail("missing@example.com")).thenReturn(Optional.empty());

        CreateConversationException exception = assertThrows(
                CreateConversationException.class,
                () -> service.create("first@example.com", "missing@example.com")
        );

        assertEquals(CreateConversationException.Reason.PARTICIPANT_NOT_FOUND, exception.getReason());
        verifyNoInteractions(conversationRepository);
    }

    @Test
    void rejectsBlankParticipantIdAsBadRequest() {
        CreateConversationException exception = assertThrows(
                CreateConversationException.class,
                () -> service.create("first@example.com", "  ")
        );

        assertEquals(CreateConversationException.Reason.INVALID_REQUEST, exception.getReason());
        verifyNoInteractions(userRepository, conversationRepository);
    }

    @Test
    void rejectsConversationWithSelfAsBadRequest() {
        when(userRepository.findByEmail("first@example.com"))
                .thenReturn(Optional.of(user("first@example.com")));

        CreateConversationException exception = assertThrows(
                CreateConversationException.class,
                () -> service.create("first@example.com", "FIRST@example.com")
        );

        assertEquals(CreateConversationException.Reason.SELF_CONVERSATION, exception.getReason());
        verifyNoInteractions(conversationRepository);
    }

    private static User user(String email) {
        return new User(email, "password-hash", "First", "User", true);
    }
}
