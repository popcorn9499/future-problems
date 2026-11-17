package com.gobison.backend.features.rides.application;

import java.util.List;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RideWriter {
    private final RideRequestRepository requests;
    private final RideOfferRepository offers;

    public RideWriter(RideRequestRepository requests, RideOfferRepository offers) {
        this.requests = requests;
        this.offers = offers;
    }

    @Transactional
    public List<RideRequest> saveRequests(List<RideRequest> rides) {
        return rides.stream().map(requests::create).toList();
    }

    @Transactional
    public List<RideOffer> saveOffers(List<RideOffer> rides) {
        return rides.stream().map(offers::create).toList();
    }
}
