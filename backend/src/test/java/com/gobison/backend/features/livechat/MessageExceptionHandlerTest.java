package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.presentation.MessageExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import static org.junit.jupiter.api.Assertions.assertEquals;

class MessageExceptionHandlerTest {

    private final MessageExceptionHandler exceptionHandler = new MessageExceptionHandler();

    @Test
    void mapsUserNotFoundToUnauthorized() {
        var response = exceptionHandler.handleGetMessages(
                new GetMessagesException(GetMessagesException.Reason.USER_NOT_FOUND));

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    }

    @Test
    void mapsInvalidLimitToBadRequest() {
        var response = exceptionHandler.handleGetMessages(
                new GetMessagesException(GetMessagesException.Reason.INVALID_LIMIT));

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    void mapsMissingConversationAndMessageToNotFound() {
        var conversationResponse = exceptionHandler.handleGetMessages(
                new GetMessagesException(GetMessagesException.Reason.CONVERSATION_NOT_FOUND));
        var messageResponse = exceptionHandler.handleGetMessages(
                new GetMessagesException(GetMessagesException.Reason.MESSAGE_NOT_FOUND));

        assertEquals(HttpStatus.NOT_FOUND, conversationResponse.getStatusCode());
        assertEquals(HttpStatus.NOT_FOUND, messageResponse.getStatusCode());
    }
}
