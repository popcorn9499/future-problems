

package com.gobison.backend.features.dashboard.infrastructure.persistence;

import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.dashboard.domain.repository.RideAgreementSummaryRepository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class RideAgreementSummaryRepositoryImpl
        implements RideAgreementSummaryRepository {

    private final JdbcTemplate jdbcTemplate;

    public RideAgreementSummaryRepositoryImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private record ListingData(
            UUID id,
            String userEmail,
            String city,
            LocalTime arrivalTime,
            LocalTime departureTime,
            String status,
            String rideType,
            UUID roundTripId
    ) {}

    @Override
    public List<RideAgreementSummary> findByMemberEmail(String email) {
        String sql = """
            SELECT
                ra.agreement_id,
                ra.offer_id,
                ra.request_id
            FROM ride_agreements ra
            JOIN ride_agreement_members ram
                ON ram.agreement_id = ra.agreement_id
            WHERE LOWER(ram.user_email) = LOWER(?)
            ORDER BY ra.created_at DESC
            """;

        List<List<RideAgreementSummary>> agreementLegs =
                jdbcTemplate.query(sql, (rs, rowNum) -> {

            long agreementId = rs.getLong("agreement_id");

            UUID offerId = rs.getObject("offer_id", UUID.class);
            UUID requestId = rs.getObject("request_id", UUID.class);

            boolean isOffer = offerId != null;
            UUID listingId = isOffer ? offerId : requestId;

            ListingData listing = findListing(isOffer, listingId);

            List<AgreementMember> drivers =
                    findMembers(agreementId, "DRIVER");

            List<AgreementMember> passengers =
                    findMembers(agreementId, "PASSENGER");

            List<RideAgreementSummary> legs = new ArrayList<>();

            // Add the original listing.
            legs.add(buildLeg(
                    agreementId,
                    listing,
                    isOffer,
                    email,
                    drivers,
                    passengers
            ));

            // If this is a round trip, retrieve and add the other leg.
            if (listing.roundTripId() != null) {
                ListingData otherLeg = findRoundTripLeg(
                        isOffer,
                        listing.roundTripId(),
                        listing.rideType()
                );

                legs.add(buildLeg(
                        agreementId,
                        otherLeg,
                        isOffer,
                        email,
                        drivers,
                        passengers
                ));
            }

            return legs;
        }, email);

        return agreementLegs.stream()
                .flatMap(List::stream)
                .toList();
    }

    private ListingData findListing(boolean isOffer, UUID listingId) {
        String table = isOffer ? "ride_offers" : "ride_requests";
        String idColumn = isOffer ? "offer_id" : "request_id";

        String sql = """
            SELECT
                %s AS id,
                user_email,
                city,
                arrival_time,
                departure_time,
                status,
                ride_type,
                round_trip_id
            FROM %s
            WHERE %s = ?
            """.formatted(idColumn, table, idColumn);

        return jdbcTemplate.queryForObject(
                sql,
                (rs, rowNum) -> new ListingData(
                        rs.getObject("id", UUID.class),
                        rs.getString("user_email"),
                        rs.getString("city"),
                        rs.getObject("arrival_time", LocalTime.class),
                        rs.getObject("departure_time", LocalTime.class),
                        rs.getString("status"),
                        rs.getString("ride_type"),
                        rs.getObject("round_trip_id", UUID.class)
                ),
                listingId
        );
    }

    private RideAgreementSummary buildLeg(
            long agreementId,
            ListingData listing,
            boolean isOffer,
            String currentUserEmail,
            List<AgreementMember> drivers,
            List<AgreementMember> passengers
    ) {
        String origin;
        String destination;

        if ("ARRIVAL".equals(listing.rideType())) {
            origin = listing.city();
            destination = "University of Manitoba";
        } else {
            origin = "University of Manitoba";
            destination = listing.city();
        }

        return new RideAgreementSummary(
                agreementId,
                listing.id(),
                listing.roundTripId(),
                listing.rideType(),
                origin,
                destination,
                listing.arrivalTime(),
                listing.departureTime(),
                findDays(isOffer, listing.id()),
                listing.status(),
                listing.userEmail().equalsIgnoreCase(currentUserEmail),
                drivers,
                passengers
        );
    }

    private ListingData findRoundTripLeg(
            boolean isOffer,
            UUID roundTripId,
            String currentRideType
    ) {
        String table = isOffer ? "ride_offers" : "ride_requests";
        String idColumn = isOffer ? "offer_id" : "request_id";

        String sql = """
            SELECT
                %s AS id,
                user_email,
                city,
                arrival_time,
                departure_time,
                status,
                ride_type,
                round_trip_id
            FROM %s
            WHERE round_trip_id = ?
              AND ride_type <> ?
            """.formatted(idColumn, table);

        return jdbcTemplate.queryForObject(
                sql,
                (rs, rowNum) -> new ListingData(
                        rs.getObject("id", UUID.class),
                        rs.getString("user_email"),
                        rs.getString("city"),
                        rs.getObject("arrival_time", LocalTime.class),
                        rs.getObject("departure_time", LocalTime.class),
                        rs.getString("status"),
                        rs.getString("ride_type"),
                        rs.getObject("round_trip_id", UUID.class)
                ),
                roundTripId,
                currentRideType
        );
    }

    private List<DayOfWeek> findDays(
            boolean isOffer,
            UUID listingId
    ) {
        String table = isOffer ? "ride_offer_days" : "ride_request_days";
        String idColumn = isOffer ? "offer_id" : "request_id";

        String sql = """
            SELECT day_of_week
            FROM %s
            WHERE %s = ?
            ORDER BY CASE day_of_week
                WHEN 'MONDAY' THEN 1
                WHEN 'TUESDAY' THEN 2
                WHEN 'WEDNESDAY' THEN 3
                WHEN 'THURSDAY' THEN 4
                WHEN 'FRIDAY' THEN 5
            END
            """.formatted(table, idColumn);

        return jdbcTemplate.query(
                sql,
                (rs, rowNum) ->
                        DayOfWeek.valueOf(rs.getString("day_of_week")),
                listingId
        );
    }

    private List<AgreementMember> findMembers(
            long agreementId,
            String role
    ) {
        String sql = """
            SELECT
                u.email,
                u.first_name,
                COALESCE(u.last_name, '') AS last_name
            FROM ride_agreement_members ram
            JOIN users u ON u.email = ram.user_email
            WHERE ram.agreement_id = ?
              AND ram.role = ?
            ORDER BY u.first_name, u.last_name
            """;

        return jdbcTemplate.query(
                sql,
                (rs, rowNum) -> new AgreementMember(
                        rs.getString("email"),
                        rs.getString("first_name"),
                        rs.getString("last_name")
                ),
                agreementId,
                role
        );
    }
}
