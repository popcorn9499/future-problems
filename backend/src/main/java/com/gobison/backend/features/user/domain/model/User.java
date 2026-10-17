package com.gobison.backend.features.user.domain.model;

public class User {

    private String umNetId;
    private String firstName;
    private String lastName;
    private boolean verified;
    private String password;

    public User(String umNetId, String password, String firstName,
                String lastName, boolean verified) {
        this.umNetId = umNetId;
        this.password = password;
        this.firstName = firstName;
        this.lastName = lastName;
        this.verified = verified;
    }

    public String getUmNetId() {
        return umNetId;
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

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public void setVerified(boolean verified) {
        this.verified = verified;
    }
}