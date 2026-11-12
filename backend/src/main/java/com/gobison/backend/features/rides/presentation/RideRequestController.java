package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.CreateRideRequestService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/rides/requests")
public class RideRequestController {

    private final CreateRideRequestService service;

    public RideRequestController(CreateRideRequestService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RideRequestResponse create(
            Authentication authentication,
            @Valid @RequestBody CreateRideRequestRequest request) {
        return RideRequestResponse.from(service.create(authentication.getName(), request));
    }
}
