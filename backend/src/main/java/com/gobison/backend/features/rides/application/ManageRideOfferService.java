package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.application.geocoding.Geocoder;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideType;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.presentation.UpdateRideOfferRequest;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.EnumSet;
import java.util.List;
import java.util.UUID;

@Service
public class ManageRideOfferService {

    private final UserRepository users;
    private final RideOfferRepository offers;
    private final Geocoder geocoder;

    public ManageRideOfferService(UserRepository users, RideOfferRepository offers, Geocoder geocoder) {
        this.users = users;
        this.offers = offers;
        this.geocoder = geocoder;
    }

    @Transactional(readOnly = true)
    public RideOffer getForOwner(String email, UUID offerId) {
        var user = users.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!user.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }

        var offer = offers.findById(offerId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Ride offer not found"));
        if (!user.getEmail().equals(offer.getUserId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only manage your own ride offers");
        }
        return offer;
    }

    public List<RideOffer> update(String email, UUID offerId, UpdateRideOfferRequest form) {
        var current = getForOwner(email, offerId);
        var legs = legsForEdit(current);
        if (legs.stream().anyMatch(leg -> "CANCELLED".equals(leg.getStatus()))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cancelled offers cannot be edited");
        }
        boolean hasArrival = legs.stream().anyMatch(leg -> leg.getRideType() == RideType.ARRIVAL);
        boolean hasDeparture = legs.stream().anyMatch(leg -> leg.getRideType() == RideType.DEPARTURE);
        if (hasArrival != (form.arrivalTime() != null) || hasDeparture != (form.departureTime() != null)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Provide a time for each leg");
        }
        var arrival = hasArrival ? LocalTime.parse(form.arrivalTime()) : null;
        var departure = hasDeparture ? LocalTime.parse(form.departureTime()) : null;
        if (hasArrival && hasDeparture && !departure.isAfter(arrival)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Departure must be later than arrival");
        }

        var city = form.city().trim();
        var street = form.streetAddress().trim();
        var description = form.description() == null ? "" : form.description().trim();
        boolean moved = legs.stream().anyMatch(leg ->
                !city.equals(leg.getCity()) || !street.equals(leg.getStreetAddress()));
        var location = moved ? geocoder.locate(street, city) : null;
        var edited = legs.stream().map(leg -> {
            boolean arriving = leg.getRideType() == RideType.ARRIVAL;
            var offer = new RideOffer(leg.getRideType(), arriving ? null : departure, leg.getRoundTripId(),
                    leg.getOfferId(), leg.getUserId(), city, street, arriving ? arrival : null,
                    EnumSet.copyOf(form.daysOfWeek()), description.isEmpty() ? null : description,
                    leg.getStatus(), form.passengerNum(), form.askingForDrivers());
            offer.setLocation(moved ? location : leg.getLocation());
            return offer;
        }).toList();

        return offers.updateIfEditable(current.getUserId(), edited).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.CONFLICT, "Offer changed or has other participants"));
    }

    private List<RideOffer> legsForEdit(RideOffer current) {
        if (current.getRoundTripId() == null && current.getRideType() != RideType.ROUND_TRIP) {
            return List.of(current);
        }
        if (current.getRoundTripId() != null) {
            var legs = offers.findRoundTripLegs(current.getRoundTripId(), current.getUserId());
            if (legs.size() == 2
                    && legs.stream().anyMatch(leg -> current.getOfferId().equals(leg.getOfferId()))
                    && legs.stream().anyMatch(leg -> leg.getRideType() == RideType.ARRIVAL)
                    && legs.stream().anyMatch(leg -> leg.getRideType() == RideType.DEPARTURE)) {
                return legs;
            }
        }
        throw new ResponseStatusException(HttpStatus.CONFLICT, "Incomplete round-trip offer");
    }
}
