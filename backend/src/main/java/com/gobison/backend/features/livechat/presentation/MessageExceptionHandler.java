package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.GetMessagesException;
import com.gobison.backend.features.livechat.application.SendMessageException;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.TransactionException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = MessageController.class)
public class MessageExceptionHandler {

    @ExceptionHandler(GetMessagesException.class)
    public ResponseEntity<Void> handleGetMessages(GetMessagesException exception) {
        HttpStatus status = switch (exception.getReason()) {
            case USER_NOT_FOUND -> HttpStatus.UNAUTHORIZED;
            case INVALID_LIMIT -> HttpStatus.BAD_REQUEST;
            case CONVERSATION_NOT_FOUND, MESSAGE_NOT_FOUND -> HttpStatus.NOT_FOUND;
        };
        return ResponseEntity.status(status).build();
    }

    @ExceptionHandler(SendMessageException.class)
    public ResponseEntity<Void> handleSendMessage(SendMessageException exception) {
        HttpStatus status = switch (exception.getReason()) {
            case INVALID_CONTENT -> HttpStatus.BAD_REQUEST;
            case NOT_PARTICIPANT -> HttpStatus.FORBIDDEN;
            case CONVERSATION_NOT_FOUND -> HttpStatus.NOT_FOUND;
        };
        return ResponseEntity.status(status).build();
    }

    @ExceptionHandler({DataAccessException.class, TransactionException.class})
    public ResponseEntity<Void> handlePersistenceFailure(RuntimeException exception) {
        return ResponseEntity.internalServerError().build();
    }
}
