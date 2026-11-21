package com.gobison.backend.features.user.application;

import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DeleteAccountService {
    private final UserRepository users;
    private final RideOfferRepository offers;
    private final RideRequestRepository requests;

    public DeleteAccountService(
            UserRepository users, RideOfferRepository offers, RideRequestRepository requests) {
        this.users = users;
        this.offers = offers;
        this.requests = requests;
    }

    @Transactional
    public void delete(String email) {
        var activeUser = users.lockActiveByEmail(email);
        if (activeUser.isEmpty()) {
            // An already deleted account is a no-op, including its legacy listings.
            users.findByEmail(email)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
            return;
        }

        var user = activeUser.get();
        user.setDeleted(true);
        users.save(user);
        offers.cancelOpenForOwner(user.getEmail());
        requests.cancelOpenForOwner(user.getEmail());
    }
}
