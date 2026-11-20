package com.gobison.backend.features.rides.presentation;

import com.gobison.backend.features.rides.application.CreateRideRequestService;
import com.gobison.backend.features.rides.application.GetRideRequestsService;
import jakarta.validation.Valid;
import com.gobison.backend.features.rides.domain.model.RideRequest;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/rides/requests")
public class RideRequestController {

    private final CreateRideRequestService createService;
    private final GetRideRequestsService getService;

    public RideRequestController(
            CreateRideRequestService createService,
            GetRideRequestsService getService) {
        this.createService = createService;
        this.getService = getService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RideRequestResponse create(
            Authentication authentication,
            @Valid @RequestBody CreateRideRequestRequest request) {
        return RideRequestResponse.from(createService.create(authentication.getName(), request));
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    public RideRequestListResponse getRequests(
            Authentication authentication,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String daysOfWeek,
            @RequestParam(required = false) String rideType,
            @RequestParam(required = false) String departureTime,
            @RequestParam(required = false) String arrivalTime,
            @RequestParam(required = false) String status) {
        
        
        List<RideRequest> rawRequests = getService.getRequests(
                authentication.getName(),
                city,
                daysOfWeek,
                rideType,
                departureTime,
                arrivalTime,
                status
        );

        // Group round-trip legs by roundTripId and keep single legs separate
        Map<UUID, List<RideRequest>> roundTripGroups = new HashMap<>();
        List<RideRequest> singleLegs = new ArrayList<>();

        for (RideRequest request : rawRequests) {
            if (request.getRoundTripId() != null) {
                roundTripGroups.computeIfAbsent(request.getRoundTripId(), k -> new ArrayList<>()).add(request);
            } else {
                singleLegs.add(request);
            }
        }

        List<RideRequestResponse> responseLegs = new ArrayList<>();

        // Map single legs
        for (RideRequest single : singleLegs) {
            responseLegs.add(RideRequestResponse.from(List.of(single)));
        }

        // Map round trips using your existing multi-leg mapper
        for (List<RideRequest> group : roundTripGroups.values()) {
            responseLegs.add(RideRequestResponse.from(group));
        }

        return RideRequestListResponse.of(responseLegs);
    }
}