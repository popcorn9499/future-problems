package com.gobison.backend.features.dashboard.presentation;

import com.gobison.backend.features.dashboard.application.DashboardService;
import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.security.SecurityConfiguration;

import jakarta.servlet.ServletException;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Needs spring-security-test on the test classpath for user().
 *
 * SecurityConfiguration is imported on purpose: it ends with
 * anyRequest().denyAll(), so these tests also fail if the dashboard rule is
 * removed or loosened.
 */
@WebMvcTest(controllers = DashboardController.class, properties = "spring.config.import=")
@Import(SecurityConfiguration.class)
class DashboardControllerTest {

    private static final String URL = "/api/v1/dashboard/agreements";
    private static final String EMAIL = "ada@myumanitoba.ca";

    @Autowired private MockMvc mvc;
    @MockitoBean private DashboardService service;

    private static RideAgreementSummary agreement(
            Long agreementId,
            String rideType,
            LocalTime arrivalTime,
            LocalTime departureTime,
            UUID roundTripId
    ) {
        return new RideAgreementSummary(
                agreementId,
                UUID.fromString("3f2b8c1e-0000-4000-8000-000000000001"),
                roundTripId,
                rideType,
                "Steinbach",
                "University of Manitoba",
                arrivalTime,
                departureTime,
                List.of(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY),
                "OPEN",
                true,
                List.of(new AgreementMember(EMAIL, "Ada", "Lovelace")),
                List.of(new AgreementMember("pat@myumanitoba.ca", "Pat", "Passenger"))
        );
    }

    @Test
    void rejectsRequestWithoutSessionWithoutCallingService() throws Exception {
        mvc.perform(get(URL))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(service);
    }

    @Test
    void asksServiceForTheLoggedInUsersAgreements() throws Exception {
        when(service.getAgreementsFor(EMAIL)).thenReturn(List.of());

        mvc.perform(get(URL).with(user(EMAIL)))
                .andExpect(status().isOk());

        verify(service).getAgreementsFor(EMAIL);
        verifyNoMoreInteractions(service);
    }

    @Test
    void respondsWithJson() throws Exception {
        when(service.getAgreementsFor(EMAIL)).thenReturn(List.of());

        mvc.perform(get(URL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    void returnsEmptyArrayWhenUserHasNoAgreements() throws Exception {
        when(service.getAgreementsFor(EMAIL)).thenReturn(List.of());

        mvc.perform(get(URL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void returnsAgreementInTheShapeTheFlutterAppExpects() throws Exception {
        UUID roundTripId = UUID.fromString("3f2b8c1e-0000-4000-8000-0000000000aa");
        when(service.getAgreementsFor(EMAIL)).thenReturn(List.of(
                agreement(7L, "ARRIVAL", LocalTime.of(8, 30), LocalTime.of(16, 15), roundTripId)));

        mvc.perform(get(URL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(7))
                .andExpect(jsonPath("$[0].listingId").value("3f2b8c1e-0000-4000-8000-000000000001"))
                .andExpect(jsonPath("$[0].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$[0].rideType").value("ARRIVAL"))
                .andExpect(jsonPath("$[0].origin").value("Steinbach"))
                .andExpect(jsonPath("$[0].destination").value("University of Manitoba"))
                .andExpect(jsonPath("$[0].arrivalTime").value("08:30"))
                .andExpect(jsonPath("$[0].departureTime").value("16:15"))
                .andExpect(jsonPath("$[0].daysOfWeek[0]").value("MONDAY"))
                .andExpect(jsonPath("$[0].daysOfWeek[1]").value("WEDNESDAY"))
                .andExpect(jsonPath("$[0].status").value("OPEN"))
                .andExpect(jsonPath("$[0].createdByCurrentUser").value(true))
                .andExpect(jsonPath("$[0].drivers[0].id").value(EMAIL))
                .andExpect(jsonPath("$[0].drivers[0].firstName").value("Ada"))
                .andExpect(jsonPath("$[0].drivers[0].lastName").value("Lovelace"))
                .andExpect(jsonPath("$[0].passengers[0].id").value("pat@myumanitoba.ca"))
                // exactly these 13 fields, so nothing new (like an address) leaks in
                .andExpect(jsonPath("$[0].length()").value(13))
                .andExpect(jsonPath("$[0].drivers[0].length()").value(3));
    }

    @Test
    void returnsBothLegsOfARoundTripUnderOneAgreementId() throws Exception {
        UUID roundTripId = UUID.randomUUID();
        when(service.getAgreementsFor(EMAIL)).thenReturn(List.of(
                agreement(5L, "ARRIVAL", LocalTime.of(8, 30), null, roundTripId),
                agreement(5L, "DEPARTURE", null, LocalTime.of(16, 15), roundTripId)));

        mvc.perform(get(URL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(5))
                .andExpect(jsonPath("$[1].id").value(5))
                .andExpect(jsonPath("$[0].rideType").value("ARRIVAL"))
                .andExpect(jsonPath("$[1].rideType").value("DEPARTURE"))
                .andExpect(jsonPath("$[0].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$[1].roundTripId").value(roundTripId.toString()))
                .andExpect(jsonPath("$[1].departureTime").value("16:15"));
    }

    @Test
    void returnsListingWithNoAgreementYetWithNullAgreementId() throws Exception {
        when(service.getAgreementsFor(EMAIL)).thenReturn(List.of(
                agreement(null, "ARRIVAL", LocalTime.of(8, 30), null, null)));

        mvc.perform(get(URL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").isEmpty())
                .andExpect(jsonPath("$[0].listingId").isNotEmpty());
    }

    @Test
    void doesNotAllowWritingToTheEndpoint() throws Exception {
        mvc.perform(post(URL).with(user(EMAIL)))
                .andExpect(status().isForbidden());

        verifyNoInteractions(service);
    }

    @Test
    void deniesOtherDashboardPathsByDefault() throws Exception {
        mvc.perform(get("/api/v1/dashboard/other").with(user(EMAIL)))
                .andExpect(status().isForbidden());

        verifyNoInteractions(service);
    }

    @Test
    void doesNotReturnPartialDataWhenServiceFails() {
        when(service.getAgreementsFor(EMAIL)).thenThrow(new IllegalStateException("database unavailable"));

        ServletException thrown = assertThrows(
                ServletException.class,
                () -> mvc.perform(get(URL).with(user(EMAIL))));

        assertInstanceOf(IllegalStateException.class, thrown.getCause());
    }
}