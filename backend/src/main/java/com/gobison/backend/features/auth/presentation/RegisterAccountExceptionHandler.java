package com.gobison.backend.features.auth.presentation;

import com.gobison.backend.features.auth.application.RegisterAccountException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = RegisterAccountController.class)
public class RegisterAccountExceptionHandler {

    @ExceptionHandler(RegisterAccountException.class)
    public ResponseEntity<Void> handleRegistration(RegisterAccountException exception) {
        HttpStatus status = switch (exception.getReason()) {
            case INVALID_REQUEST -> HttpStatus.BAD_REQUEST;
            case EMAIL_ALREADY_REGISTERED, DELETED_ACCOUNT -> HttpStatus.CONFLICT;
        };
        return ResponseEntity.status(status).build();
    }
}
