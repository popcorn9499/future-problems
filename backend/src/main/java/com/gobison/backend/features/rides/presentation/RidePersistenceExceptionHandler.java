package com.gobison.backend.features.rides.presentation;

import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice(assignableTypes = {RideRequestController.class, RideOfferController.class})
public class RidePersistenceExceptionHandler {

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, String>> persistenceFailure(DataAccessException exception) {
        return ResponseEntity.internalServerError()
                .body(Map.of("message", "Unable to create ride"));
    }
}
