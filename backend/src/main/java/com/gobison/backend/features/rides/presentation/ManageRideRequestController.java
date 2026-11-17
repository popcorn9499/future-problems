package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideRequestService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/rides/requests")
public class ManageRideRequestController {

    private final ManageRideRequestService service;

    public ManageRideRequestController(ManageRideRequestService service) {
        this.service = service;
    }

    @GetMapping("/{requestId}")
    public RideRequestDetailsResponse get(
            Authentication authentication,
            @PathVariable("requestId") UUID requestId) {

        var rideRequest = service.getForOwner(
                authentication.getName(), requestId);

        return RideRequestDetailsResponse.from(rideRequest);
    }
}