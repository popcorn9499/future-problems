package com.gobison.backend.features.user.presentation;

import com.gobison.backend.features.user.application.FieldBlankException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = UserAccountController.class)
public class UserProfileExceptionHandler {

    @ExceptionHandler(FieldBlankException.class)
    public ResponseEntity<Void> handleFieldBlank(FieldBlankException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }
}
