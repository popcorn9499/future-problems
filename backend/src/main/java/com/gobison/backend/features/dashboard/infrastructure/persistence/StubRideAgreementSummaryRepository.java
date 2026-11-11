package com.gobison.backend.features.dashboard.infrastructure.persistence;


import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.dashboard.domain.repository.RideAgreementSummaryRepository;
import org.springframework.stereotype.Repository;
 
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
 
/**
 * TEMPORARY: returns hardcoded agreements until the ride request tables exist.
 *
 * When they do, write a JPA-backed implementation of
 * {@link RideAgreementSummaryRepository} (like UserRepositoryImpl) and delete
 * this class. Nothing else in the dashboard needs to change.
 */
@Repository
public class StubRideAgreementSummaryRepository implements RideAgreementSummaryRepository {
 
    @Override
    public List<RideAgreementSummary> findByMemberEmail(String email) {
        // The requesting user appears as a passenger so the "(you)" highlight
        // can be tested from the app.
        AgreementMember currentUser = new AgreementMember(email, "Test", "User", "address");
 
        return List.of(
                new RideAgreementSummary(
                        1L,
                        "Steinbach",
                        "University of Manitoba",
                        LocalTime.of(7, 45),
                        List.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY),
                        "ACTIVE",
                        List.of(
                                new AgreementMember("coless1@myumanitoba.ca", "Sasha", "Coles", "123 Main St"),
                                new AgreementMember("jankek1@myumanitoba.ca", "Kamryn", "Janke", "456 Oak Ave")
                        ),
                        List.of(
                                currentUser,
                                new AgreementMember("carinr2@myumanitoba.ca", "Carina", "Rook", "789 Pine Rd")
                        )
                ),
                new RideAgreementSummary(
                        2L,
                        "Osborne Village",
                        "University of Manitoba",
                        LocalTime.of(12, 30),
                        List.of(DayOfWeek.TUESDAY, DayOfWeek.THURSDAY),
                        "ARCHIVED",
                        List.of(new AgreementMember("soneyer1@myumanitoba.ca", "Rebekah", "Soneye", "321 Elm St")),
                        List.of(new AgreementMember("bauerl@myumanitoba.ca", "Leon", "Bauer", "654 Cedar Ave"),
                                new AgreementMember("fanr1@myumanitoba.ca", "Ruitian", "Fan", "987 Oak St"),
                                new AgreementMember("smithl3@myumanitoba.ca", "Logan", "Smith", "123 Pine Rd"), 
                                new AgreementMember("coless1@myumanitoba.ca", "Sasha", "Coles", "123 Main St"),
                                new AgreementMember("carinr2@myumanitoba.ca", "Carina", "Rook", "789 Pine Rd"))
                )
        );
    }
}
 