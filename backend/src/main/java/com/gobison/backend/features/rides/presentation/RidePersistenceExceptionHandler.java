package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.geocoding.GeocodingException;
import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice(assignableTypes = {RideRequestController.class, RideOfferController.class})
public class RidePersistenceExceptionHandler {

    @ExceptionHandler(GeocodingException.class)
    public ResponseEntity<Map<String, String>> geocodingFailure(
            GeocodingException exception) {
        return ResponseEntity.status(exception.isInvalidAddress() ? 422 : 503)
                .body(Map.of("code", exception.getCode(), "message", exception.getMessage()));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, String>> persistenceFailure(DataAccessException exception) {
        return ResponseEntity.internalServerError()
                .body(Map.of("message", "Unable to create ride"));
    }
}
