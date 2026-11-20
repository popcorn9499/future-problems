package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class GetRideRequestsService {

    private final UserRepository userRepository;
    private final RideRequestRepository rideRequestRepository;

    public GetRideRequestsService(
            UserRepository userRepository,
            RideRequestRepository rideRequestRepository) {
        this.userRepository = userRepository;
        this.rideRequestRepository = rideRequestRepository;
    }

    @Transactional(readOnly = true)
    public List<RideRequest> getRequests(
            String email,
            String city,
            String daysOfWeekParam,
            String rideTypeParam,
            String departureTimeParam,
            String arrivalTimeParam) {

        // 1. Authentication check
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        if (!user.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }

        // 2. Parse and validate query parameters
        List<DayOfWeek> daysOfWeek = new ArrayList<>();
        if (daysOfWeekParam != null && !daysOfWeekParam.isBlank()) {
            try {
                daysOfWeek = Arrays.stream(daysOfWeekParam.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .map(s -> DayOfWeek.valueOf(s.toUpperCase()))
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid day of week provided");
            }
        }

        RideType rideType = null;
        if (rideTypeParam != null && !rideTypeParam.isBlank()) {
            try {
                rideType = RideType.valueOf(rideTypeParam.trim().toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid ride type");
            }
        }

        LocalTime departureTime = null;
        if (departureTimeParam != null && !departureTimeParam.isBlank()) {
            try {
                departureTime = LocalTime.parse(departureTimeParam.trim());
            } catch (DateTimeParseException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid departureTime format (expected HH:mm)");
            }
        }

        LocalTime arrivalTime = null;
        if (arrivalTimeParam != null && !arrivalTimeParam.isBlank()) {
            try {
                arrivalTime = LocalTime.parse(arrivalTimeParam.trim());
            } catch (DateTimeParseException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid arrivalTime format (expected HH:mm)");
            }
        }

        // 3. Query repository (excluding current user's email)
        return rideRequestRepository.findFiltered(
                user.getEmail(),
                city,
                daysOfWeek,
                rideType,
                departureTime,
                arrivalTime,
                "OPEN"
        );
    }
}
