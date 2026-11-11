package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.CreateRideOfferService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/rides/offers")
public class RideOfferController {

    private final CreateRideOfferService service;

    public RideOfferController(CreateRideOfferService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RideOfferResponse create(
            Authentication authentication,
            @Valid @RequestBody CreateRideOfferRequest request) {
        return RideOfferResponse.from(service.create(authentication.getName(), request));
    }
}
