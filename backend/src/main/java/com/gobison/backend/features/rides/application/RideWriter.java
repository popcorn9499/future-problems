package com.gobison.backend.features.rides.application;

import java.util.List;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class RideWriter {
    private final RideRequestRepository requests;
    private final RideOfferRepository offers;
    private final UserRepository users;

    public RideWriter(RideRequestRepository requests, RideOfferRepository offers, UserRepository users) {
        this.requests = requests;
        this.offers = offers;
        this.users = users;
    }

    @Transactional
    public List<RideRequest> saveRequests(List<RideRequest> rides) {
        if (rides.isEmpty()) return List.of();
        requireActiveOwner(rides.getFirst().getUserId());
        return rides.stream().map(requests::create).toList();
    }

    @Transactional
    public List<RideOffer> saveOffers(List<RideOffer> rides) {
        if (rides.isEmpty()) return List.of();
        requireActiveOwner(rides.getFirst().getUserId());
        return rides.stream().map(offers::create).toList();
    }

    private void requireActiveOwner(String email) {
        var owner = users.lockActiveByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!owner.isVerified()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Email verification required");
        }
    }
}
