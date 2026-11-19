package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.application.GetMessagesService;
import com.gobison.backend.features.livechat.application.MarkMessagesReadException;
import com.gobison.backend.features.livechat.application.MarkMessagesReadService;
import com.gobison.backend.features.livechat.application.SendMessageException;
import com.gobison.backend.features.livechat.application.SendMessageService;
import com.gobison.backend.features.livechat.application.dto.MarkMessagesReadResponse;
import com.gobison.backend.features.livechat.application.dto.MessageItem;
import com.gobison.backend.features.livechat.application.dto.RetrieveMessage;
import com.gobison.backend.features.livechat.domain.model.Message;
import com.gobison.backend.features.livechat.presentation.MessageController;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = MessageController.class, properties = "spring.config.import=")
@Import(SecurityConfiguration.class)
class MessageEndpointTest {

    private static final String CURRENT_USER = "alice@example.com";
    private static final String CONVERSATION_ID = "conv_123";
    private static final String BASE_URL = "/api/v1/conversations/" + CONVERSATION_ID;

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private GetMessagesService getMessagesService;

    @MockitoBean
    private SendMessageService sendMessageService;

    @MockitoBean
    private MarkMessagesReadService markMessagesReadService;

    @MockitoBean
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail(CURRENT_USER))
                .thenReturn(Optional.of(new User(CURRENT_USER, "password", "Alice", "User", true)));
    }

    @Test
    void requiresAuthenticationForReadSendAndMarkRead() throws Exception {
        mvc.perform(get(BASE_URL + "/messages")).andExpect(status().isUnauthorized());
        mvc.perform(post(BASE_URL + "/messages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Hello\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(patch(BASE_URL + "/read")).andExpect(status().isUnauthorized());

        verifyNoInteractions(getMessagesService, sendMessageService, markMessagesReadService);
    }

    @Test
    void getsMessagesWithPaginationQueryParametersAndResponseShape() throws Exception {
        when(getMessagesService.getConversation(
                org.mockito.ArgumentMatchers.any(User.class), org.mockito.ArgumentMatchers.eq(CONVERSATION_ID),
                org.mockito.ArgumentMatchers.eq(25), org.mockito.ArgumentMatchers.eq("msg_005")))
                .thenReturn(new RetrieveMessage(
                        CONVERSATION_ID,
                        List.of(new MessageItem(
                                "msg_004", "bob@example.com", "Hello", Instant.parse("2026-11-18T12:00:00Z"), null)),
                        new RetrieveMessage.Pagination(25, true, "msg_004")));

        mvc.perform(get(BASE_URL + "/messages")
                        .with(user(CURRENT_USER))
                        .param("limit", "25")
                        .param("before", "msg_005"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conversationId").value(CONVERSATION_ID))
                .andExpect(jsonPath("$.messages[0].messageId").value("msg_004"))
                .andExpect(jsonPath("$.pagination.limit").value(25))
                .andExpect(jsonPath("$.pagination.hasMore").value(true))
                .andExpect(jsonPath("$.pagination.nextCursor").value("msg_004"));
    }

    @Test
    void mapsGetMessagesFailuresToBadRequestForbiddenAndNotFound() throws Exception {
        when(getMessagesService.getConversation(
                org.mockito.ArgumentMatchers.any(User.class), org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt(), org.mockito.ArgumentMatchers.isNull()))
                .thenAnswer(invocation -> {
                    int limit = invocation.getArgument(2);
                    if (limit == 0) {
                        throw new GetMessagesException(GetMessagesException.Reason.INVALID_LIMIT);
                    }
                    if (limit == 20) {
                        throw new GetMessagesException(GetMessagesException.Reason.NOT_PARTICIPANT);
                    }
                    throw new GetMessagesException(GetMessagesException.Reason.CONVERSATION_NOT_FOUND);
                });
        mvc.perform(get(BASE_URL + "/messages").with(user(CURRENT_USER)).param("limit", "0"))
                .andExpect(status().isBadRequest());
        mvc.perform(get(BASE_URL + "/messages").with(user(CURRENT_USER)).param("limit", "20"))
                .andExpect(status().isForbidden());
        mvc.perform(get(BASE_URL + "/messages").with(user(CURRENT_USER)))
                .andExpect(status().isNotFound());
    }

    @Test
    void sendsMessageAndReturnsCreatedResponse() throws Exception {
        var message = Message.restore(
                "msg_001", CONVERSATION_ID, CURRENT_USER, "Hello", Instant.parse("2026-11-18T12:00:00Z"), null);
        when(sendMessageService.send(
                org.mockito.ArgumentMatchers.any(User.class), org.mockito.ArgumentMatchers.eq(CONVERSATION_ID),
                org.mockito.ArgumentMatchers.eq("Hello")))
                .thenReturn(message);

        mvc.perform(post(BASE_URL + "/messages")
                        .with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Hello\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.messageId").value("msg_001"))
                .andExpect(jsonPath("$.conversationId").value(CONVERSATION_ID))
                .andExpect(jsonPath("$.senderId").value(CURRENT_USER))
                .andExpect(jsonPath("$.content").value("Hello"))
                .andExpect(jsonPath("$.readAt").value(nullValue()));
    }

    @Test
    void mapsSendMessageFailuresToBadRequestForbiddenAndNotFound() throws Exception {
        when(sendMessageService.send(
                org.mockito.ArgumentMatchers.any(User.class), org.mockito.ArgumentMatchers.eq(CONVERSATION_ID),
                org.mockito.ArgumentMatchers.eq(" ")))
                .thenThrow(new SendMessageException(SendMessageException.Reason.INVALID_CONTENT));
        mvc.perform(post(BASE_URL + "/messages")
                        .with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\" \"}"))
                .andExpect(status().isBadRequest());

        when(sendMessageService.send(
                org.mockito.ArgumentMatchers.any(User.class), org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.eq("Hello")))
                .thenAnswer(invocation -> {
                    String conversationId = invocation.getArgument(1);
                    if (conversationId.equals("conv_forbidden")) {
                        throw new SendMessageException(SendMessageException.Reason.NOT_PARTICIPANT);
                    }
                    throw new SendMessageException(SendMessageException.Reason.CONVERSATION_NOT_FOUND);
                });
        mvc.perform(post("/api/v1/conversations/conv_forbidden/messages")
                        .with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Hello\"}"))
                .andExpect(status().isForbidden());

        mvc.perform(post("/api/v1/conversations/conv_missing/messages")
                        .with(user(CURRENT_USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Hello\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void marksMessagesReadAndReturnsUpdatedMessageIds() throws Exception {
        when(markMessagesReadService.markRead(org.mockito.ArgumentMatchers.any(User.class),
                org.mockito.ArgumentMatchers.eq(CONVERSATION_ID)))
                .thenReturn(new MarkMessagesReadResponse(
                        CONVERSATION_ID,
                        2,
                        List.of("msg_001", "msg_002"),
                        Instant.parse("2026-11-18T12:00:00Z")));

        mvc.perform(patch(BASE_URL + "/read").with(user(CURRENT_USER)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conversationId").value(CONVERSATION_ID))
                .andExpect(jsonPath("$.markedAsRead").value(2))
                .andExpect(jsonPath("$.messageIds[0]").value("msg_001"))
                .andExpect(jsonPath("$.messageIds[1]").value("msg_002"))
                .andExpect(jsonPath("$.readAt").value("2026-11-18T12:00:00Z"));
    }

    @Test
    void mapsMarkReadFailuresToForbiddenAndNotFound() throws Exception {
        when(markMessagesReadService.markRead(org.mockito.ArgumentMatchers.any(User.class),
                org.mockito.ArgumentMatchers.anyString()))
                .thenAnswer(invocation -> {
                    String conversationId = invocation.getArgument(1);
                    if (conversationId.equals("conv_forbidden")) {
                        throw new MarkMessagesReadException(MarkMessagesReadException.Reason.NOT_PARTICIPANT);
                    }
                    throw new MarkMessagesReadException(MarkMessagesReadException.Reason.CONVERSATION_NOT_FOUND);
                });
        mvc.perform(patch("/api/v1/conversations/conv_forbidden/read").with(user(CURRENT_USER)))
                .andExpect(status().isForbidden());

        mvc.perform(patch("/api/v1/conversations/conv_missing/read").with(user(CURRENT_USER)))
                .andExpect(status().isNotFound());
    }
}
