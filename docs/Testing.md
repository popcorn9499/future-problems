# Testing

This is a short summary of how we test GoBison. The backend has about 240 tests in 43 files, the frontend has about 420 tests in 30 files, and both run automatically in GitHub Actions on every push and pull request.

## Approach

We test in layers. Most tests are fast and don't need a database or a browser, and a smaller number run against real infrastructure. When a test fails, the layer it belongs to should tell you roughly where the bug is.

| Layer | What it covers | Where |
| --- | --- | --- |
| Unit | Domain models, entity mapping, services, repositories, validators, controllers (Flutter) | Backend and frontend |
| Controller | One Spring controller with the real security rules, services mocked | Backend |
| Integration | Real service and repository code against PostgreSQL | Backend |
| Widget | Flutter pages rendered with fake services | Frontend |
| Browser integration | Registration and email verification in Chrome, against a mock backend | Frontend |

## Backend

Tools: JUnit, Mockito, Spring Boot test support (`@WebMvcTest`, `@SpringBootTest`), `spring-security-test`, and AssertJ in one file. Test packages mirror the production code (`auth`, `dashboard`, `livechat`, `rides`, `user`).

### Unit tests

Domain and entity tests are plain JUnit. They check constructors, getters and setters, and that entities map to domain objects and back without losing fields (`UserTest`, `MessageTest`, `RideEntityMappingTest`).

Services and repository classes are tested with Mockito. Most of the effort goes into edge cases and failure paths:

- **Auth and accounts:** registration normalises the email and hashes the password, rejects duplicates, and blocks a deleted account's email from being reused. Profile updates only change the fields that were sent and reject blank values. `SessionAuthenticationServiceTest` checks that only the authenticated username is stored in the session and no credentials.
- **Messaging:** conversations can't be created with yourself or with a missing user. Message pages use a cursor and a limit, with separate errors for a missing conversation and a non-participant, and the fetch limit doesn't overflow at the integer maximum. Marking messages read returns the updated ids.
- **Rides:** owners can read and edit their own request or offer, but not after someone else has joined. Round trips update both legs and keep their ids. An edit is dropped if the address lookup is cancelled or a participant joins between checks.
- **Transactions:** `RideWriterTransactionTest` wraps the writer in a real transaction proxy and checks that the two legs of a round trip commit together or roll back together.
- **Geocoding:** `NominatimGeocoderTest` mocks the HTTP client and clock, so the real service is never called. It checks that only Canadian, confident matches are accepted, and that results are cached and expire. It also checks that failures aren't cached, that calls are spaced out, and that concurrent identical lookups are merged.
- **Email:** `EmailServiceTest` checks the sender, recipient and body, and that SMTP failures reach the caller.

### Controller tests

Each controller has a `@WebMvcTest` with `@Import(SecurityConfiguration.class)`, so the real security rules apply. That config ends with `anyRequest().denyAll()`, so a test fails if an endpoint is accidentally left open. Services are replaced with `@MockitoBean`, and a logged-in session is simulated.

They check:

- **Authentication:** requests without a session get 401, and the service is never called.
- **Status codes:** 400 for invalid input, 403 for a non-owner or an unverified or deleted account, 404 for missing records, and 409 for conflicts such as a duplicate email or an edit that clashes with another change.
- **Response shape:** the JSON fields match what the frontend expects. The dashboard test asserts the exact field count so nothing new leaks into the response.
- **Safety:** wrong HTTP methods and unknown paths are refused, malformed JSON is rejected, and persistence errors don't expose details to the client.
- **Login flow:** login creates a session, logout invalidates it, a deleted account can't log in even with the right password, and deleting an account ends the current session.

### Integration tests

Five classes use `@SpringBootTest` against a real PostgreSQL database: the dashboard service and repository, `RideRequestParticipantsTest`, `UserRepositoryImplTest` and the email verification service. We don't use H2 or Testcontainers, so the SQL runs on the same engine we deploy on.

- **Dashboard:** covers email matching with different case and spaces, an unjoined listing, a joined agreement with its drivers and passengers, round-trip legs under one agreement, the creator appearing once, members ordered by name, and no data from other users.
- **Users:** saving and loading every field, updating, deleting, defaults such as avatar colour, and concurrent creates not overwriting an account.
- **Ride participants:** an owner alone doesn't count as another participant, and a member on the return leg is detected from either leg.
- **Email verification:** the real service with only the mail sender mocked, so no emails are sent.

Tests clean up after themselves, either with `@Transactional` or with `DashboardTestData`, a shared helper that creates users and listings and deletes them afterwards.

In CI, the database only gets tables for JPA entities (`create-drop`). The dashboard queries use `JdbcTemplate`, so those tests load `ci_ride_agreements_schema.sql` with `@Sql` to create the ride tables if they don't exist.

## Frontend

Tools: `flutter_test` and `http/testing` (`MockClient`). Tests are in `frontend/test`, grouped by feature (`auth`, `dashboard`, `messages`, `profile`, `map`, `ride_offer`, `ride_request`, `core`).

Most features follow the same pattern, and each layer tests something different:

- **Service tests** use `MockClient` to fake HTTP responses. They check the request that gets sent (URL, method, body) and how responses and errors are parsed.
- **Controller tests** use a fake service (e.g. `FakeDashboardService`). They check state and error handling: loading flags, listeners being notified, and the right message for each HTTP status (400, 401, 500, unknown). They also check that input is trimmed, blank optional fields become null, and that the right times are sent for arriving, departing and round-trip rides.
- **Widget tests** render the page with a fake service. They check form validation, weekday selection, what the user sees for loading, empty and error states, and what happens on taps.
- **Validator tests** cover form rules for auth and profile.

By feature:

- **Auth:** registration, login and email verification, validators, and the session gate that decides between login, verification and the app. It also checks that a 401 clears a cached session, and that a server failure offers a retry instead of logging out.
- **Dashboard:** the filtering and visibility rules, the page layout, the service parsing, and the owner flows for editing and cancelling an offer.
- **Ride offers and requests:** creating each ride type, the forms, and parsing the created-ride summaries from real JSON.
- **Profile:** viewing, editing and deleting an account.
- **Messages:** the inbox, previews and unread counts, and opening a chat and sending a message.
- **Map:** the filter controls (ride type, status, days, show offers and requests) and clearing filters.
- **Core:** app shell navigation, the collapsible sidebar, and session storage.

### Browser integration tests

The browser integration tests live in `frontend/integration_test/` (11 tests). They run the real app in Chrome through ChromeDriver, with a mock backend instead of the real API, and cover the sign-up flow:

- **Registration form:** a signed-out app opens the login page and can reach registration. An empty form shows the required-field errors, a full email address is rejected (only the UMNetID is accepted), and passwords that are too short or missing an uppercase letter, a lowercase letter or a number are rejected.
- **Registration responses:** a duplicate email and a server error each show the right message, the user stays on the form, and the button works again afterwards.
- **Email verification:** a wrong code shows an error, and the correct code opens the home page.

## Coverage

The backend uses JaCoCo, configured in `pom.xml`. The agent attaches during `test` and the report is generated in the `verify` phase. The frontend uses `flutter test --coverage` and `genhtml`.

Where to find the reports:

- **On GitHub:** open the run in the Actions tab and scroll to Artifacts at the bottom. `flutter-coverage` (from Flutter CI) contains `html/index.html`, and `backend-coverage` (from Backend CI) contains `index.html`. Download, unzip and open the HTML file in a browser.
- **Locally, frontend:** run `flutter test --coverage` in `frontend/`. The raw data is `frontend/coverage/lcov.info`. For the HTML version, run `genhtml coverage/lcov.info --output-directory coverage/html` (needs `lcov` installed) and open `frontend/coverage/html/index.html`.
- **Locally, backend:** run `./mvnw verify` in `backend/` and open `backend/target/site/jacoco/index.html`.

The frontend report comes from `flutter test`, so it covers the unit and widget tests but not the integration tests.
