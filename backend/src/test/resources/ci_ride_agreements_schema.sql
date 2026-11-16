-- Ride listing and agreement tables for the CI / test database.
-- Mirrors the Supabase schema. Safe to run more than once.
-- Requires the users table (primary key: email) to exist already.
--
-- Left out on purpose: the nullable `location geography` column on ride_offers
-- and ride_requests. It needs PostGIS, and nothing in the dashboard code or
-- tests uses it. Add it here if CI runs a postgis/postgis image and other
-- code needs it.

CREATE TABLE IF NOT EXISTS ride_offers (
    offer_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email         text    NOT NULL REFERENCES users (email) ON DELETE CASCADE,
    city               varchar NOT NULL,
    street_address     varchar NOT NULL,
    arrival_time       time,
    description        text,
    status             varchar NOT NULL DEFAULT 'OPEN',
    passenger_num      bigint  NOT NULL,
    asking_for_drivers boolean NOT NULL DEFAULT false,
    departure_time     time,
    round_trip_id      uuid,
    ride_type          varchar NOT NULL DEFAULT 'ARRIVAL'
);

CREATE TABLE IF NOT EXISTS ride_offer_days (
    offer_id    uuid    NOT NULL REFERENCES ride_offers (offer_id) ON DELETE CASCADE,
    day_of_week varchar NOT NULL,
    PRIMARY KEY (offer_id, day_of_week)
);

CREATE TABLE IF NOT EXISTS ride_requests (
    request_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email     text    NOT NULL REFERENCES users (email) ON DELETE CASCADE,
    city           varchar NOT NULL,
    street_address varchar NOT NULL,
    arrival_time   time,
    description    text,
    status         varchar NOT NULL DEFAULT 'OPEN',
    departure_time time,
    round_trip_id  uuid,
    ride_type      varchar NOT NULL DEFAULT 'ARRIVAL'
);

CREATE TABLE IF NOT EXISTS ride_request_days (
    request_id  uuid    NOT NULL REFERENCES ride_requests (request_id) ON DELETE CASCADE,
    day_of_week varchar NOT NULL,
    PRIMARY KEY (request_id, day_of_week)
);

CREATE TABLE IF NOT EXISTS ride_agreements (
    agreement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offer_id     uuid UNIQUE REFERENCES ride_offers (offer_id) ON DELETE CASCADE,
    request_id   uuid UNIQUE REFERENCES ride_requests (request_id) ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    CHECK (num_nonnulls(offer_id, request_id) = 1)
);

CREATE TABLE IF NOT EXISTS ride_agreement_members (
    agreement_id bigint  NOT NULL REFERENCES ride_agreements (agreement_id) ON DELETE CASCADE,
    user_email   varchar NOT NULL REFERENCES users (email) ON DELETE CASCADE,
    role         varchar NOT NULL CHECK (role IN ('DRIVER', 'PASSENGER')),
    joined_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (agreement_id, user_email)
);