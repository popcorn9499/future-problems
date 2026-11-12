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
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import org.mockito.ArgumentCaptor;
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
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.hamcrest.Matchers.nullValue;
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
                .andExpect(jsonPath("$.userId").value(email))
                .andExpect(jsonPath("$.requestId").isNotEmpty())
                .andExpect(jsonPath("$.status").value("OPEN"))
                .andExpect(jsonPath("$.city").value("Winnipeg"))
                .andExpect(jsonPath("$.arrivalTime").value("08:30"))
                .andExpect(jsonPath("$.daysOfWeek.length()").value(2))
                .andExpect(jsonPath("$.daysOfWeek[0]").value("MONDAY"));
    }

    @Test
    void createsOfferWithDefaultDriverOption() throws Exception {
        account(true);
        mvc.perform(post("/api/v1/rides/offers")
                        .with(user(email))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"status\":\"CLOSED\"", "\"passengerNum\":3")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.offerId").isNotEmpty())
                .andExpect(jsonPath("$.userId").value(email))
                .andExpect(jsonPath("$.askingForDrivers").value(false));
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
                .andExpect(jsonPath("$.passengerNum").value(3));
    }

    @Test
    void createsRoundTripSummariesAndPreservesSavedLegIds() throws Exception {
        account(true);

        for (String endpoint : new String[] {"requests", "offers"}) {
            clearInvocations(rideRequestRepository, rideOfferRepository);
            String roundTripBody = body.replace("\"arriving\"", "\"roundTrip\"")
                    .replace("\"status\":\"CLOSED\"", "\"passengerNum\":3,\"departureTime\":\"16:30\"");
            String idField = endpoint.equals("requests") ? "requestId" : "offerId";
            var result = mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(roundTripBody))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$").isMap())
                    .andExpect(jsonPath("$.rideType").value("roundTrip"))
                    .andExpect(jsonPath("$.arrivalTime").value("08:30"))
                    .andExpect(jsonPath("$.departureTime").value("16:30"))
                    .andExpect(jsonPath("$." + idField).value(nullValue()))
                    .andExpect(jsonPath("$.arrivalId").isNotEmpty())
                    .andExpect(jsonPath("$.departureId").isNotEmpty())
                    .andExpect(jsonPath("$.roundTripId").isNotEmpty())
                    .andExpect(jsonPath("$.userId").value(email))
                    .andExpect(jsonPath("$.city").value("Winnipeg"))
                    .andExpect(jsonPath("$.status").value("OPEN"))
                    .andReturn();

            var json = new ObjectMapper().readTree(result.getResponse().getContentAsString());
            assertNotEquals(json.get("arrivalId").asText(), json.get("departureId").asText());
            if (endpoint.equals("requests")) {
                var captor = ArgumentCaptor.forClass(
                        RideRequest.class);
                verify(rideRequestRepository, times(2)).create(captor.capture());
                var arrival = captor.getAllValues().get(0);
                var departure = captor.getAllValues().get(1);
                assertEquals(arrival.getRequestId().toString(), json.get("arrivalId").asText());
                assertEquals(departure.getRequestId().toString(), json.get("departureId").asText());
                assertEquals(arrival.getRoundTripId(), departure.getRoundTripId());
                assertEquals(arrival.getRoundTripId().toString(), json.get("roundTripId").asText());
                assertEquals(arrival.getUserId(), departure.getUserId());
                assertEquals(arrival.getDaysOfWeek(), departure.getDaysOfWeek());
            } else {
                var captor = ArgumentCaptor.forClass(
                        RideOffer.class);
                verify(rideOfferRepository, times(2)).create(captor.capture());
                var arrival = captor.getAllValues().get(0);
                var departure = captor.getAllValues().get(1);
                assertEquals(arrival.getOfferId().toString(), json.get("arrivalId").asText());
                assertEquals(departure.getOfferId().toString(), json.get("departureId").asText());
                assertEquals(arrival.getRoundTripId(), departure.getRoundTripId());
                assertEquals(arrival.getRoundTripId().toString(), json.get("roundTripId").asText());
                assertEquals(arrival.getPassengerNum(), departure.getPassengerNum());
                assertEquals(arrival.isAskingForDrivers(), departure.isAskingForDrivers());
                assertEquals(3, json.get("passengerNum").asInt());
            }
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
            String idField = endpoint.equals("requests") ? "requestId" : "offerId";
            clearInvocations(rideRequestRepository, rideOfferRepository);
            String oneWayBody = body.replace(
                    "\"status\":\"CLOSED\"", "\"passengerNum\":3,\"departureTime\":\"16:30\"");

            mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(oneWayBody))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.rideType").value("arriving"))
                    .andExpect(jsonPath("$.arrivalId").isNotEmpty())
                    .andExpect(jsonPath("$.departureId").value(nullValue()))
                    .andExpect(jsonPath("$.departureTime").isEmpty())
                    .andExpect(jsonPath("$.roundTripId").value(nullValue()))
                    .andExpect(jsonPath("$." + idField).isNotEmpty());

            mvc.perform(post("/api/v1/rides/" + endpoint)
                            .with(user(email))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(oneWayBody.replace("\"arriving\"", "\"departing\"")))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.rideType").value("departing"))
                    .andExpect(jsonPath("$.departureId").isNotEmpty())
                    .andExpect(jsonPath("$.arrivalId").value(nullValue()))
                    .andExpect(jsonPath("$.arrivalTime").isEmpty())
                    .andExpect(jsonPath("$.roundTripId").isEmpty());
        }
    }
}
