package com.gobison.backend.features.livechat.presentation;

import com.gobison.backend.features.livechat.application.CreateConversationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = CreateConversationController.class)
public class CreateConversationExceptionHandler {

    @ExceptionHandler(CreateConversationException.class)
    public ResponseEntity<Void> handleCreateConversation(CreateConversationException exception) {
        HttpStatus status = switch (exception.getReason()) {
            case INVALID_REQUEST, SELF_CONVERSATION -> HttpStatus.BAD_REQUEST;
            case CURRENT_USER_NOT_FOUND, PARTICIPANT_NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONVERSATION_ALREADY_EXISTS -> HttpStatus.CONFLICT;
        };
        return ResponseEntity.status(status).build();
    }
}
