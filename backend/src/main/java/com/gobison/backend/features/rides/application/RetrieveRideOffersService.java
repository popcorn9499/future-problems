package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
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
public class RetrieveRideOffersService {

    private final UserRepository userRepository;
    private final RideOfferRepository rideOfferRepository;

    public RetrieveRideOffersService(
            UserRepository userRepository,
            RideOfferRepository rideOfferRepository) {
        this.userRepository = userRepository;
        this.rideOfferRepository = rideOfferRepository;
    }

    @Transactional(readOnly = true)
    public List<RideOffer> retrieve(
            String email,
            String city,
            String daysOfWeekStr,
            String rideTypeStr,
            String departureTimeStr,
            String arrivalTimeStr,
            boolean includeOwn) {

        // 1. Verify user session / existence
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));

        if (!user.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }

        List<DayOfWeek> daysOfWeek = new ArrayList<>();
        if (daysOfWeekStr != null && !daysOfWeekStr.isBlank()) {
            try {
                daysOfWeek = Arrays.stream(daysOfWeekStr.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .map(s -> DayOfWeek.valueOf(s.toUpperCase()))
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid day of week provided");
            }
        }

        RideType rideType = null;
        Boolean isRoundTrip = null;
        if (rideTypeStr != null && !rideTypeStr.isBlank()) {
            String normalizedType = rideTypeStr.trim().toLowerCase();
            switch (normalizedType) {
                case "arriving", "arrival" -> rideType = RideType.ARRIVAL;
                case "departing", "departure" -> rideType = RideType.DEPARTURE;
                case "roundtrip", "round_trip" -> isRoundTrip = true;
                default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid ride type");
            }
        }

        LocalTime departureTime = null;
        if (departureTimeStr != null && !departureTimeStr.isBlank()) {
            try {
                departureTime = LocalTime.parse(departureTimeStr.trim());
            } catch (DateTimeParseException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid departureTime format (expected HH:mm)");
            }
        }

        LocalTime arrivalTime = null;
        if (arrivalTimeStr != null && !arrivalTimeStr.isBlank()) {
            try {
                arrivalTime = LocalTime.parse(arrivalTimeStr.trim());
            } catch (DateTimeParseException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid arrivalTime format (expected HH:mm)");
            }
        }

        // 3. Fetch from repository
        return rideOfferRepository.findFilteredOffers(
                includeOwn ? null : user.getEmail(),
                city,
                daysOfWeek,
                rideType,
                isRoundTrip,
                departureTime,
                arrivalTime,
                "OPEN"
        );
    }
}
