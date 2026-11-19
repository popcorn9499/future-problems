package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.ManageRideOfferService;
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
@RequestMapping("/api/v1/rides/offers")
public class ManageRideOfferController {

    private final ManageRideOfferService service;

    public ManageRideOfferController(ManageRideOfferService service) {
        this.service = service;
    }

    @GetMapping("/{offerId}")
    public RideOfferResponse get(Authentication authentication, @PathVariable("offerId") UUID offerId) {
        var offer = service.getForOwner(authentication.getName(), offerId);
        return RideOfferResponse.from(List.of(offer));
    }

    @PatchMapping("/{offerId}")
    public RideOfferResponse update(Authentication authentication, @PathVariable("offerId") UUID offerId,
            @Valid @RequestBody UpdateRideOfferRequest form) {
        return RideOfferResponse.from(service.update(authentication.getName(), offerId, form));
    }

    @DeleteMapping("/{offerId}")
    public ResponseEntity<Map<String, String>> cancel(Authentication authentication,
            @PathVariable("offerId") UUID offerId,
            @RequestParam(name = "confirmParticipants", defaultValue = "false") boolean confirmParticipants) {
        var result = service.cancel(authentication.getName(), offerId, confirmParticipants);
        return switch (result) {
            case CANCELLED -> ResponseEntity.noContent().build();
            case CONFIRMATION_REQUIRED -> ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("code", result.name()));
            case OFFER_CHANGED -> ResponseEntity.status(HttpStatus.CONFLICT).build();
        };
    }
}
