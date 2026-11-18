package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.CreateConversationService;
import com.gobison.backend.features.livechat.application.CreateConversationException;
import com.gobison.backend.features.livechat.domain.model.Conversation;
import com.gobison.backend.features.livechat.domain.repository.ConversationRepository;
import com.gobison.backend.features.livechat.presentation.ConversationController;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ConversationController.class, properties = "spring.config.import=")
@Import(SecurityConfiguration.class)
class CreateConversationEndpointTest {

    private static final String ENDPOINT = "/api/v1/conversation";
    private static final String CURRENT_USER = "first@example.com";
    private static final String PARTICIPANT = "second@example.com";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private CreateConversationService service;

    @Test
    void requiresAuthentication() throws Exception {
        mvc.perform(post(ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"participantId\":\"" + PARTICIPANT + "\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(service);
    }

    @Test
    void rejectsMissingBlankAndInvalidParticipantIds() throws Exception {
        for (String body : List.of(
                "{}",
                "{\"participantId\":\" \"}",
                "{\"participantId\":\"not-an-email\"}")) {
            mvc.perform(post(ENDPOINT).with(user(CURRENT_USER))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isBadRequest());
        }

        verifyNoInteractions(service);
    }

    @Test
    void returnsNotFoundWhenParticipantDoesNotExist() throws Exception {
        when(service.create(CURRENT_USER, PARTICIPANT))
                .thenThrow(new CreateConversationException(
                        CreateConversationException.Reason.PARTICIPANT_NOT_FOUND));

        mvc.perform(post(ENDPOINT).with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"participantId\":\"" + PARTICIPANT + "\"}"))
                .andExpect(status().isNotFound());

        verify(service).create(CURRENT_USER, PARTICIPANT);
    }

    @Test
    void returnsBadRequestWhenCreatingConversationWithSelf() throws Exception {
        when(service.create(CURRENT_USER, CURRENT_USER))
                .thenThrow(new CreateConversationException(CreateConversationException.Reason.SELF_CONVERSATION));

        mvc.perform(post(ENDPOINT).with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"participantId\":\"" + CURRENT_USER + "\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void returnsConflictWhenConversationAlreadyExists() throws Exception {
        when(service.create(CURRENT_USER, PARTICIPANT))
                .thenReturn(new ConversationRepository.CreateResult(
                        new Conversation("conversation-123", List.of(CURRENT_USER, PARTICIPANT)),
                        false));

        mvc.perform(post(ENDPOINT).with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"participantId\":\"" + PARTICIPANT + "\"}"))
                .andExpect(status().isConflict());
    }

    @Test
    void createsConversationForValidParticipant() throws Exception {
        when(service.create(CURRENT_USER, PARTICIPANT))
                .thenReturn(new ConversationRepository.CreateResult(
                        new Conversation("conversation-123", List.of(CURRENT_USER, PARTICIPANT)),
                        true));

        mvc.perform(post(ENDPOINT).with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"participantId\":\"" + PARTICIPANT + "\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.conversationId").value("conversation-123"))
                .andExpect(jsonPath("$.participants[0]").value(CURRENT_USER))
                .andExpect(jsonPath("$.participants[1]").value(PARTICIPANT))
                .andExpect(jsonPath("$.createdAt").exists());
    }
}
