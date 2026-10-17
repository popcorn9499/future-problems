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
    @Column(name = "um_net_id", nullable = false)
    private String umNetId;

    @Column(name = "password", nullable = false)
    private String password;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(name = "verified", nullable = false)
    private boolean verified;

    // Required by JPA
    protected UserEntity() {
    }

    public UserEntity(
            String umNetId,
            String password,
            String firstName,
            String lastName,
            boolean verified) {
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
