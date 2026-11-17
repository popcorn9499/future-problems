package com.gobison.backend.features.user.domain.model;

public class User {

    private String email;
    private String firstName;
    private String lastName;
    private boolean verified;
    private String verificationCode; 
    private String password;
    private boolean deleted;

    public User(String email, String password, String firstName, String lastName, boolean verified) {
        this.email = email;
        this.password = password;
        this.firstName = firstName;
        this.lastName = lastName;
        this.verified = verified;
    }

    public String getEmail() {
        return email;
    }

    public String getPassword() {
        return password;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public boolean isVerified() {
        return verified;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public String getVerificationCode() {
        return verificationCode;
    }

    public void setVerificationCode(String verificationCode) {
        this.verificationCode = verificationCode;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public void setVerified(boolean verified) {
        this.verified = verified;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }
}
