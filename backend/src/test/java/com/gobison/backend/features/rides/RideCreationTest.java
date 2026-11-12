package com.gobison.backend.features.rides;

import com.gobison.backend.features.rides.application.CreateRideOfferService;
import com.gobison.backend.features.rides.application.CreateRideRequestService;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.rides.presentation.RideOfferController;
import com.gobison.backend.features.rides.presentation.RideRequestController;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;
import tools.jackson.databind.ObjectMapper;

import java.util.Optional;

import static org.mockito.Mockito.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = {RideRequestController.class, RideOfferController.class},
        properties = "spring.config.import=")
@Import({SecurityConfiguration.class, CreateRideRequestService.class, CreateRideOfferService.class})
class RideCreationTest {

    @Autowired
    MockMvc mvc;

    @MockitoBean
    UserRepository userRepository;

    @MockitoBean
    RideRequestRepository rideRequestRepository;

    @MockitoBean
    RideOfferRepository rideOfferRepository;

    private final String email = "ada@myumanitoba.ca";

    private final String body = """
        {"rideType":"arriving","city":" Winnipeg ","streetAddress":" 123 Main ","arrivalTime":"08:30",
        "daysOfWeek":["FRIDAY","MONDAY","MONDAY"],"description":"  ",
        "userId":"attacker@example.com","status":"CLOSED"}
        """;

    private void account(boolean verified) {
        when(userRepository.findByEmail(email))
                .thenReturn(Optional.of(new User(email, "secret", "Ada", "Lovelace", verified)));
        when(rideRequestRepository.create(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(rideOfferRepository.create(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void createsOwnedRequestWithNormalizedSchedule() throws Exception {
        account(true);
        mvc.perform(post("/api/v1/rides/requests")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$[0].userId").value(email))
                .andExpect(jsonPath("$[0].requestId").isNotEmpty())
                .andExpect(jsonPath("$[0].status").value("OPEN"))
                .andExpect(jsonPath("$[0].city").value("Winnipeg"))
                .andExpect(jsonPath("$[0].arrivalTime").value("08:30"))
                .andExpect(jsonPath("$[0].daysOfWeek.length()").value(2))
                .andExpect(jsonPath("$[0].daysOfWeek[0]").value("MONDAY"));
    }

    @Test
    void createsOfferWithDefaultDriverOption() throws Exception {
        account(true);
        mvc.perform(post("/api/v1/rides/offers")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":3")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$[0].offerId").isNotEmpty())
                .andExpect(jsonPath("$[0].userId").value(email))
                .andExpect(jsonPath("$[0].askingForDrivers").value(false));
    }

    @Test
    void rejectsUnauthenticatedAndUnverifiedUsers() throws Exception {
        for (String path : new String[] {"requests", "offers"}) {
            mvc.perform(post("/api/v1/rides/" + path)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":3")))
                .andExpect(status().isUnauthorized());
            account(false);
            mvc.perform(post("/api/v1/rides/" + path)
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":3")))
                .andExpect(status().isForbidden());
        }
        verifyNoInteractions(rideRequestRepository, rideOfferRepository);
    }

    @Test
    void rejectsDeletedAccount() throws Exception {
        when(userRepository.findByEmail(email)).thenReturn(Optional.empty());
        mvc.perform(post("/api/v1/rides/requests")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(rideRequestRepository);
    }

    @Test
    void rejectsInvalidFields() throws Exception {
        account(true);
        for (String invalid : new String[] {
                body.replace("08:30", "8:30"),
                body.replace("08:30", "24:00"),
                body.replace(" Winnipeg ", " "),
                body.replace("[\"FRIDAY\",\"MONDAY\",\"MONDAY\"]", "[]"),
                body.replace("FRIDAY", "FUNDAY"),
                body.replace("\"FRIDAY\"", "null"),
                "{}",
                "{"}) {
            mvc.perform(post("/api/v1/rides/requests")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalid))
                .andExpect(status().isBadRequest());
        }
        for (String seats : new String[] {
                "0", "-1", "null", "0.9", "-2.9", "2147483648", "\"invalid\""}) {
            mvc.perform(post("/api/v1/rides/offers")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":" + seats)))
                .andExpect(status().isBadRequest());
        }
        verifyNoInteractions(rideRequestRepository, rideOfferRepository);
    }

    @Test
    void truncatesDecimalPassengerCounts() throws Exception {
        account(true);

        mvc.perform(post("/api/v1/rides/offers")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":3.9")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$[0].passengerNum").value(3));
    }

    @Test
    void createsRoundTripsAndDepartureLegsForBothEndpoints() throws Exception {
        account(true);

        for (String endpoint : new String[] {"requests", "offers"}) {
            String roundTripBody = body.replace("\"arriving\"", "\"roundTrip\"")
                    .replace("\"status\":\"CLOSED\"", "\"passengerNum\":3,\"departureTime\":\"16:30\"");
            var result = mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(roundTripBody))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.length()").value(2))
                    .andExpect(jsonPath("$[0].rideType").value("arriving"))
                    .andExpect(jsonPath("$[0].arrivalTime").value("08:30"))
                    .andExpect(jsonPath("$[0].departureTime").isEmpty())
                    .andExpect(jsonPath("$[1].rideType").value("departing"))
                    .andExpect(jsonPath("$[1].departureTime").value("16:30"))
                    .andExpect(jsonPath("$[1].arrivalTime").isEmpty())
                    .andExpect(jsonPath("$[0].userId").value(email))
                    .andExpect(jsonPath("$[1].userId").value(email))
                    .andExpect(jsonPath("$[0].roundTripId").isNotEmpty())
                    .andReturn();

            var json = new ObjectMapper()
                    .readTree(result.getResponse().getContentAsString());
            assertEquals(
                    json.get(0).get("roundTripId").asText(),
                    json.get(1).get("roundTripId").asText());
            String idField = endpoint.equals("requests") ? "requestId" : "offerId";
            assertNotEquals(
                    json.get(0).get(idField).asText(), json.get(1).get(idField).asText());
            for (String field : new String[] {
                    "userId", "city", "streetAddress", "daysOfWeek", "description", "status"}) {
                assertEquals(json.get(0).get(field), json.get(1).get(field));
            }
            if (endpoint.equals("offers")) {
                assertEquals(json.get(0).get("passengerNum"), json.get(1).get("passengerNum"));
                assertEquals(json.get(0).get("askingForDrivers"), json.get(1).get("askingForDrivers"));
            }

            mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(roundTripBody.replace("\"roundTrip\"", "\"departing\"")
                                    .replace("\"arrivalTime\":\"08:30\",", "")))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].rideType").value("departing"))
                    .andExpect(jsonPath("$[0].arrivalTime").isEmpty())
                    .andExpect(jsonPath("$[0].departureTime").value("16:30"))
                    .andExpect(jsonPath("$[0].roundTripId").isEmpty());
        }
    }

    @Test
    void rejectsInvalidTypesAndConditionalTimesForBothEndpoints() throws Exception {
        account(true);

        for (String endpoint : new String[] {"requests", "offers"}) {
            String validBody = body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":3");
            for (String invalidBody : new String[] {
                    validBody.replace("\"rideType\":\"arriving\",", ""),
                    validBody.replace("\"arriving\"", "\"ARRIVAL\""),
                    validBody.replace("\"arriving\"", "\"unknown\""),
                    validBody.replace("\"arriving\"", "null"),
                    validBody.replace("\"arrivalTime\":\"08:30\",", ""),
                    validBody.replace("\"arriving\"", "\"departing\""),
                    validBody.replace("\"arriving\"", "\"roundTrip\""),
                    validBody.replace("\"arrivalTime\":\"08:30\"", "\"arrivalTime\":\"08:30\",\"departureTime\":\"bad\""),
                    validBody.replace("\"arriving\"", "\"roundTrip\"")
                            .replace("\"arrivalTime\":\"08:30\"", "\"arrivalTime\":\"08:30\",\"departureTime\":\"08:30\""),
                    validBody.replace("\"arriving\"", "\"roundTrip\"")
                            .replace("\"arrivalTime\":\"08:30\"", "\"arrivalTime\":\"08:30\",\"departureTime\":\"07:00\""),
                    validBody.replace("\"arriving\"", "\"departing\"")
                            .replace("\"arrivalTime\":\"08:30\"", "\"arrivalTime\":\"bad\",\"departureTime\":\"16:30\"")}) {
                mvc.perform(post("/api/v1/rides/" + endpoint)
                                .with(user(email))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(invalidBody))
                        .andExpect(status().isBadRequest());
            }
        }

        verifyNoInteractions(rideRequestRepository, rideOfferRepository);
    }

    @Test
    void ignoresValidUnusedTimesOnOneWayTrips() throws Exception {
        account(true);

        for (String endpoint : new String[] {"requests", "offers"}) {
            String oneWayBody = body.replace(
                    "\"status\":\"CLOSED\"", "\"passengerNum\":3,\"departureTime\":\"16:30\"");

            mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(oneWayBody))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].rideType").value("arriving"))
                    .andExpect(jsonPath("$[0].departureTime").isEmpty())
                    .andExpect(jsonPath("$[0].roundTripId").isEmpty());

            mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(oneWayBody.replace("\"arriving\"", "\"departing\"")))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.length()").value(1))
                    .andExpect(jsonPath("$[0].rideType").value("departing"))
                    .andExpect(jsonPath("$[0].arrivalTime").isEmpty())
                    .andExpect(jsonPath("$[0].roundTripId").isEmpty());
        }
    }
}
