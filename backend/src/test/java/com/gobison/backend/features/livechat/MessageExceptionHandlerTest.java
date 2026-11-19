package com.gobison.backend.features.livechat;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.application.MarkMessagesReadException;
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

    @Test
    void mapsNonParticipantToForbidden() {
        var response = exceptionHandler.handleGetMessages(
                new GetMessagesException(GetMessagesException.Reason.NOT_PARTICIPANT));

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void mapsMarkReadErrorsToExpectedStatuses() {
        var unauthorized = exceptionHandler.handleMarkMessagesRead(
                new MarkMessagesReadException(MarkMessagesReadException.Reason.USER_NOT_FOUND));
        var forbidden = exceptionHandler.handleMarkMessagesRead(
                new MarkMessagesReadException(MarkMessagesReadException.Reason.NOT_PARTICIPANT));
        var notFound = exceptionHandler.handleMarkMessagesRead(
                new MarkMessagesReadException(MarkMessagesReadException.Reason.CONVERSATION_NOT_FOUND));

        assertEquals(HttpStatus.UNAUTHORIZED, unauthorized.getStatusCode());
        assertEquals(HttpStatus.FORBIDDEN, forbidden.getStatusCode());
        assertEquals(HttpStatus.NOT_FOUND, notFound.getStatusCode());
    }
}
