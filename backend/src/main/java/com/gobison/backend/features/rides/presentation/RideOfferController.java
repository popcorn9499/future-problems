package com.gobison.backend.features.rides.presentation;


import com.gobison.backend.features.rides.application.CreateRideOfferService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;


import com.gobison.backend.features.rides.application.RetrieveRideOffersService;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.features.user.domain.model.User;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/rides/offers")
public class RideOfferController {

    private final CreateRideOfferService createService;
    private final RetrieveRideOffersService getService;
    private final UserRepository users;

    public RideOfferController(
            CreateRideOfferService createService,
            RetrieveRideOffersService getService,
            UserRepository users) {
        this.createService = createService;
        this.getService = getService;
        this.users = users;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RideOfferResponse create(
            Authentication authentication,
            @Valid @RequestBody CreateRideOfferRequest request) {
        return RideOfferResponse.from(createService.create(authentication.getName(), request));
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    public RideOfferListResponse retrieveOffers(
            Authentication authentication,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String daysOfWeek,
            @RequestParam(required = false) String rideType,
            @RequestParam(required = false) String departureTime,
            @RequestParam(required = false) String arrivalTime) {

        List<RideOffer> rawOffers = getService.retrieve(
                authentication.getName(),
                city,
                daysOfWeek,
                rideType,
                departureTime,
                arrivalTime
        );

        // Group round-trip legs by roundTripId and keep single legs separate
        Map<UUID, List<RideOffer>> roundTripGroups = new HashMap<>();
        List<RideOffer> singleLegs = new ArrayList<>();

        for (RideOffer offer : rawOffers) {
            if (offer.getRoundTripId() != null) {
                roundTripGroups.computeIfAbsent(offer.getRoundTripId(), k -> new ArrayList<>()).add(offer);
            } else {
                singleLegs.add(offer);
            }
        }

        Map<String, User> owners = rawOffers.isEmpty() ? Map.of()
                : users.findAllByEmail(rawOffers.stream().map(RideOffer::getUserId).distinct().toList());
        List<RideOfferResponse> responseLegs = new ArrayList<>();

        // Map single legs
        for (RideOffer single : singleLegs) {
            responseLegs.add(RideOfferResponse.from(
                    List.of(single), RidePosterResponse.from(owners.get(single.getUserId()))));
        }

        // Map round trips using your existing multi-leg mapper
        for (List<RideOffer> group : roundTripGroups.values()) {
            responseLegs.add(RideOfferResponse.from(
                    group, RidePosterResponse.from(owners.get(group.getFirst().getUserId()))));
        }

        return RideOfferListResponse.of(responseLegs);
    }
}
