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

import java.util.Optional;

import static org.mockito.Mockito.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
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
        {"city":" Winnipeg ","streetAddress":" 123 Main ","arrivalTime":"08:30",
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
}
