package com.gobison.backend.features.user.domain.model;

public class User {

    public static final String DEFAULT_AVATAR_COLOR = "#E9DFD2";

    private String email;
    private String firstName;
    private String lastName;
    private boolean verified;
    private String verificationCode; 
    private String password;
    private boolean deleted;

    private String gender;
    private Integer age;
    private String description;
    private String avatarColor = DEFAULT_AVATAR_COLOR;

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

    public void setGender(String gender) { this.gender = gender; }

    public String getGender() { return gender; }

    public void setAge(Integer age) { this.age = age; }

    public Integer getAge() { return age; }

    public void setDescription(String description) { this.description = description; }

    public String getDescription() { return description; }

    public void setAvatarColor(String avatarColor) { this.avatarColor = avatarColor; }

    public String getAvatarColor() { return avatarColor; }
}
