package com.gobison.backend.features.rides.application;

import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Service
public class ManageRideOfferService {

    private final UserRepository users;
    private final RideOfferRepository offers;

    public ManageRideOfferService(UserRepository users, RideOfferRepository offers) {
        this.users = users;
        this.offers = offers;
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
}
