package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideRequestService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
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

    @PatchMapping("/{requestId}")
    public RideRequestDetailsResponse update(
            Authentication authentication,
            @PathVariable("requestId") UUID requestId,
            @Valid @RequestBody UpdateRideRequestRequest form) {

        var rideRequest = service.updateOneWay(
                authentication.getName(), requestId, form);

        return RideRequestDetailsResponse.from(rideRequest);
    }

    @PatchMapping("/{requestId}/round-trip")
    public List<RideRequestDetailsResponse> updateRoundTrip(
            Authentication authentication,
            @PathVariable("requestId") UUID requestId,
            @Valid @RequestBody UpdateRideRequestRequest form) {

        var legs = service.updateRoundTrip(
                authentication.getName(), requestId, form);

        return legs.stream()
                .map(RideRequestDetailsResponse::from)
                .toList();
    }

    @DeleteMapping("/{requestId}")
    public ResponseEntity<Map<String, String>> cancel(
            Authentication authentication,
            @PathVariable("requestId") UUID requestId,
            @RequestParam(name = "confirmParticipants", defaultValue = "false") boolean confirmParticipants) {

        var result = service.cancel(authentication.getName(), requestId, confirmParticipants);

        return switch (result) {
            case CANCELLED -> ResponseEntity.noContent().build();
            case CONFIRMATION_REQUIRED -> ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("code", result.name()));
        };
    }
}