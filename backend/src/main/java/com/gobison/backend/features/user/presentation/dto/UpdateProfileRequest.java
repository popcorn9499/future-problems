package com.gobison.backend.features.user.presentation.dto;

import com.fasterxml.jackson.annotation.JsonSetter;

public class UpdateProfileRequest {

    private String firstName;
    private String lastName;
    private Integer age;
    private String gender;
    private String description;
    private String avatarColor;
    private boolean firstNameProvided;
    private boolean lastNameProvided;
    private boolean ageProvided;
    private boolean genderProvided;
    private boolean descriptionProvided;
    private boolean avatarColorProvided;

    public String getFirstName() {
        return firstName;
    }

    @JsonSetter("firstName")
    public void setFirstName(String firstName) {
        this.firstName = firstName;
        this.firstNameProvided = true;
    }

    public boolean hasFirstName() {
        return firstNameProvided;
    }

    public String getLastName() {
        return lastName;
    }

    @JsonSetter("lastName")
    public void setLastName(String lastName) {
        this.lastName = lastName;
        this.lastNameProvided = true;
    }

    public boolean hasLastName() {
        return lastNameProvided;
    }

    public Integer getAge() {
        return age;
    }

    @JsonSetter("age")
    public void setAge(Integer age) {
        this.age = age;
        this.ageProvided = true;
    }

    public boolean hasAge() {
        return ageProvided;
    }

    public String getGender() {
        return gender;
    }

    @JsonSetter("gender")
    public void setGender(String gender) {
        this.gender = gender;
        this.genderProvided = true;
    }

    public boolean hasGender() {
        return genderProvided;
    }

    public String getDescription() {
        return description;
    }

    @JsonSetter("description")
    public void setDescription(String description) {
        this.description = description;
        this.descriptionProvided = true;
    }

    public boolean hasDescription() {
        return descriptionProvided;
    }

    public String getAvatarColor() {
        return avatarColor;
    }

    @JsonSetter("avatarColor")
    public void setAvatarColor(String avatarColor) {
        this.avatarColor = avatarColor;
        this.avatarColorProvided = true;
    }

    public boolean hasAvatarColor() {
        return avatarColorProvided;
    }
}
