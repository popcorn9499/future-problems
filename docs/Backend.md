# Backend Documentation

## Installation Instructions

Requirements

- Java 21+
- Postgres

Setup

- Setup local.properties use [local.properties.example](../backend/local.properties.example) as a template
- run 'java -jar backend.jar'

### Local.properties Configuration

`SUPABASE_DB_URL` should be the url to the postgres database.
`SUPABASE_DB_USERNAME` should be the postgres user that can access the database.
`SUPABASE_DB_PASSWORD` should be the postgres password.
`MAIL_PASSWORD` should be the password for the mail account

## Testing

run tests via `./mvnw clean test` or `.\mvnw clean test` depending on if you run the superior Linux or Windows(cough cough more like Windblows)

## Core Features

### User

handles all the database information regarding the User.
This includes

- Email address
- First and Last name
- Verified status
- Password Hashing

### Auth

Handles email verification as well as registering the user

the hashed password is hashed using spring frameworks crypto password encoder function.

### Ride management

The dashboard uses the following endpoints under `/api/v1/rides`.
Send the session cookie of the verified user who posted the ride.
Use the UUID of a single leg for `{id}`, including for round trips.

| Method | Path | Successful response |
| --- | --- | --- |
| GET | `/requests/{id}` | Details of the selected request leg |
| GET | `/offers/{id}` | Details of the selected offer leg, including seats and driver preference |
| PATCH | `/requests/{id}` | Updated one-way request |
| PATCH | `/requests/{id}/round-trip` | Array containing the updated arrival and departure legs |
| PATCH | `/offers/{id}` | Updated offer. A round trip includes `arrivalId` and `departureId` |
| DELETE | `/requests/{id}` or `/offers/{id}` | `204 No Content` |

For PATCH, send the full edit form as JSON. Include `city`, `streetAddress`,
a nonempty `daysOfWeek` list (for example, `["MONDAY"]`), and the times in
`HH:mm` format. A one-way ride takes its direction's time. A round trip takes
both `arrivalTime` and `departureTime`, with departure later than arrival.
The optional `description` can be cleared. Offers also require an integer
`passengerNum` of at least 1 and a boolean `askingForDrivers`.

Cancelled rides and rides with another participant return `409` on edit.
An invalid address returns `422 INVALID_ADDRESS`. A temporary geocoding
failure returns `503 GEOCODING_UNAVAILABLE`.

When another participant has joined, DELETE returns `409` with
`{"code":"CONFIRMATION_REQUIRED"}`. After the owner confirms, repeat DELETE
with `?confirmParticipants=true`. Cancellation sets the status to `CANCELLED`
on all legs and preserves the ride and membership records.
