package com.gobison.backend.features.user.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "users")

//maps the user record to PostgreSQL using JPA
public class UserEntity {
    
    @Id
    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "password", nullable = false)
    private String password;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "verified", nullable = false)
    private boolean verified;

    @Column(name = "is_deleted", nullable = false)
    private Boolean deleted = false;

    @Column(name = "verification_code", length = 6)
    private String verificationCode;

    // Required by JPA
    protected UserEntity() {
    }

    public UserEntity(
            String email,
            String password,
            String firstName,
            String lastName,
            boolean verified) {
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
        return Boolean.TRUE.equals(deleted);
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
