package com.gobison.backend.features.user.application;

public class FieldBlankException extends RuntimeException {

    private final String field;

    public FieldBlankException(String field) {
        super(field + " cannot be null or blank");
        this.field = field;
    }

    public String getField() {
        return field;
    }
}
