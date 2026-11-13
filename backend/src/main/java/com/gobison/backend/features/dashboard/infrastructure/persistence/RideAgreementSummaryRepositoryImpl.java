


package com.gobison.backend.features.dashboard.infrastructure.persistence;

import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.dashboard.domain.repository.RideAgreementSummaryRepository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
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
            UUID roundTripId,
            boolean isOffer
    ) {}

    private record AgreementReference(
            long agreementId,
            boolean isOffer,
            UUID listingId
    ) {}

    @Override
    @Transactional(readOnly = true)
    public List<RideAgreementSummary> findByMemberEmail(String email) {

        List<RideAgreementSummary> results = new ArrayList<>();

        /*
         * Find agreements involving this user.
         *
         * A user is included if they are either:
         * - a member of the agreement, or
         * - the creator of the listing referenced by the agreement.
         *
         * The LEFT JOINs allow us to check either offers or requests.
         */
        String agreementSql = """
            SELECT DISTINCT
                ra.agreement_id,
                ra.offer_id,
                ra.request_id
            FROM ride_agreements ra
            LEFT JOIN ride_agreement_members ram
                ON ram.agreement_id = ra.agreement_id
            LEFT JOIN ride_offers ro
                ON ra.offer_id = ro.offer_id
            LEFT JOIN ride_requests rr
                ON ra.request_id = rr.request_id
            WHERE ram.user_email = ?
               OR ro.user_email = ?
               OR rr.user_email = ?
            ORDER BY ra.agreement_id
            """;

        List<AgreementReference> agreements = jdbcTemplate.query(
                agreementSql,
                (rs, rowNum) -> {
                    UUID offerId = rs.getObject("offer_id", UUID.class);
                    UUID requestId = rs.getObject("request_id", UUID.class);

                    boolean isOffer = offerId != null;
                    UUID listingId = isOffer ? offerId : requestId;

                    return new AgreementReference(
                            rs.getLong("agreement_id"),
                            isOffer,
                            listingId
                    );
                },
                email,
                email,
                email
        );

        /*
         * Process agreements after the original query has completed.
         * This avoids running additional queries while its ResultSet
         * is still open.
         */
        for (AgreementReference agreement : agreements) {

            ListingData listing = findListing(
                    agreement.isOffer(),
                    agreement.listingId()
            );

            if (listing == null) {
                continue;
            }

            List<AgreementMember> drivers =
                    findMembers(agreement.agreementId(), "DRIVER");

            List<AgreementMember> passengers =
                    findMembers(agreement.agreementId(), "PASSENGER");

            // Add the listing referenced by the agreement.
            results.add(buildLeg(
                    agreement.agreementId(),
                    listing,
                    email,
                    drivers,
                    passengers
            ));

            /*
             * A round trip has two listing rows but only one agreement.
             * Find the other leg and give it the same agreement ID
             * and participant lists.
             */
            if (listing.roundTripId() != null) {

                ListingData otherLeg = findRoundTripLeg(
                        agreement.isOffer(),
                        listing.roundTripId(),
                        listing.rideType()
                );

                if (otherLeg != null) {
                    results.add(buildLeg(
                            agreement.agreementId(),
                            otherLeg,
                            email,
                            drivers,
                            passengers
                    ));
                }
            }
        }

        /*
         * Find the user's own listings that do not have an agreement.
         * Both legs of an unjoined round trip are returned separately.
         */
        List<ListingData> unjoinedListings =
                findOwnListingsWithoutAgreement(email);

        for (ListingData listing : unjoinedListings) {

            List<AgreementMember> owner =
                    findOwner(listing.userEmail());

            /*
             * The creator of an offer is always a driver.
             * The creator of a request is a passenger.
             */
            List<AgreementMember> drivers =
                    listing.isOffer() ? owner : List.of();

            List<AgreementMember> passengers =
                    listing.isOffer() ? List.of() : owner;

            results.add(buildLeg(
                    null,
                    listing,
                    email,
                    drivers,
                    passengers
            ));
        }

        return results;
    }

    private ListingData findListing(
            boolean isOffer,
            UUID listingId
    ) {
        if (listingId == null) {
            return null;
        }

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

        List<ListingData> listings = jdbcTemplate.query(
                sql,
                (rs, rowNum) -> mapListing(rs, isOffer),
                listingId
        );

        return listings.size() == 1 ? listings.get(0) : null;
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

        List<ListingData> listings = jdbcTemplate.query(
                sql,
                (rs, rowNum) -> mapListing(rs, isOffer),
                roundTripId,
                currentRideType
        );

        /*
         * A valid round trip should have exactly one other leg.
         * Return null if the paired leg is missing or the data
         * contains multiple matching rows.
         */
        return listings.size() == 1 ? listings.get(0) : null;
    }

    private ListingData mapListing(
            ResultSet rs,
            boolean isOffer
    ) throws SQLException {

        return new ListingData(
                rs.getObject("id", UUID.class),
                rs.getString("user_email"),
                rs.getString("city"),
                rs.getObject("arrival_time", LocalTime.class),
                rs.getObject("departure_time", LocalTime.class),
                rs.getString("status"),
                rs.getString("ride_type"),
                rs.getObject("round_trip_id", UUID.class),
                isOffer
        );
    }

    private RideAgreementSummary buildLeg(
            Long agreementId,
            ListingData listing,
            String currentUserEmail,
            List<AgreementMember> drivers,
            List<AgreementMember> passengers
    ) {
        String origin;
        String destination;

        switch (listing.rideType()) {
            case "ARRIVAL" -> {
                origin = listing.city();
                destination = "University of Manitoba";
            }
            case "DEPARTURE" -> {
                origin = "University of Manitoba";
                destination = listing.city();
            }
            default -> throw new IllegalStateException(
                    "Unexpected ride type: " + listing.rideType()
            );
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
                findDays(listing.isOffer(), listing.id()),
                listing.status(),
                listing.userEmail().equalsIgnoreCase(currentUserEmail),
                drivers,
                passengers
        );
    }

    private List<DayOfWeek> findDays(
            boolean isOffer,
            UUID listingId
    ) {
        String table = isOffer
                ? "ride_offer_days"
                : "ride_request_days";

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

    private List<ListingData> findOwnListingsWithoutAgreement(
            String email
    ) {
        String sql = """
            SELECT
                o.offer_id AS id,
                o.user_email,
                o.city,
                o.arrival_time,
                o.departure_time,
                o.status,
                o.ride_type,
                o.round_trip_id,
                TRUE AS is_offer
            FROM ride_offers o
            WHERE o.user_email = ?
              AND NOT EXISTS (
                  SELECT 1
                  FROM ride_agreements ra
                  JOIN ride_offers linked
                      ON linked.offer_id = ra.offer_id
                  WHERE linked.offer_id = o.offer_id
                     OR (
                         o.round_trip_id IS NOT NULL
                         AND linked.round_trip_id = o.round_trip_id
                     )
              )

            UNION ALL

            SELECT
                r.request_id AS id,
                r.user_email,
                r.city,
                r.arrival_time,
                r.departure_time,
                r.status,
                r.ride_type,
                r.round_trip_id,
                FALSE AS is_offer
            FROM ride_requests r
            WHERE r.user_email = ?
              AND NOT EXISTS (
                  SELECT 1
                  FROM ride_agreements ra
                  JOIN ride_requests linked
                      ON linked.request_id = ra.request_id
                  WHERE linked.request_id = r.request_id
                     OR (
                         r.round_trip_id IS NOT NULL
                         AND linked.round_trip_id = r.round_trip_id
                     )
              )
            """;

        return jdbcTemplate.query(
                sql,
                (rs, rowNum) -> new ListingData(
                        rs.getObject("id", UUID.class),
                        rs.getString("user_email"),
                        rs.getString("city"),
                        rs.getObject("arrival_time", LocalTime.class),
                        rs.getObject("departure_time", LocalTime.class),
                        rs.getString("status"),
                        rs.getString("ride_type"),
                        rs.getObject("round_trip_id", UUID.class),
                        rs.getBoolean("is_offer")
                ),
                email,
                email
        );
    }

    private List<AgreementMember> findOwner(String email) {
        String sql = """
            SELECT
                email,
                first_name,
                COALESCE(last_name, '') AS last_name
            FROM users
            WHERE email = ?
            """;

        return jdbcTemplate.query(
                sql,
                (rs, rowNum) -> new AgreementMember(
                        rs.getString("email"),
                        rs.getString("first_name"),
                        rs.getString("last_name")
                ),
                email
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
            JOIN users u
                ON u.email = ram.user_email
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
