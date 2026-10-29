package com.gobison.backend.features.auth.presentation;

import com.gobison.backend.features.auth.application.EmailVerificationService;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import com.gobison.backend.security.SessionAuthenticationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mail.MailSendException;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = {LoginController.class, EmailVerificationController.class, CurrentUserController.class},
        properties = "spring.config.import=")
@Import({SecurityConfiguration.class, SessionAuthenticationService.class, MailDeliveryExceptionHandler.class})
class LoginControllerTest {
    @Autowired MockMvc mvc;
    @Autowired PasswordEncoder passwords;
    @MockitoBean UserRepository users;
    @MockitoBean EmailVerificationService verification;

    private User account(boolean verified) {
        var user = new User("ada@myumanitoba.ca", passwords.encode("password"), "Ada", "Lovelace", verified);
        when(users.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        return user;
    }

    @Test
    void loginCreatesSessionUsableForVerification() throws Exception {
        account(false);
        var result = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\" ADA@myumanitoba.ca \",\"password\":\"password\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.userId").value("ada@myumanitoba.ca"))
                .andExpect(jsonPath("$.user.verified").value(false))
                .andExpect(jsonPath("$.user.password").doesNotExist()).andReturn();
        verify(verification).sendVerificationCode("ada@myumanitoba.ca");
        var session = (MockHttpSession) result.getRequest().getSession(false);
        assertNotNull(session);
        mvc.perform(post("/api/v1/auth/verify-email").session(session)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"code\":\"123456\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.universityVerified").value(true));
        verify(verification).verifyEmail("ada@myumanitoba.ca", "123456");
    }

    @Test
    void currentUserRequiresAndRestoresSession() throws Exception {
        mvc.perform(get("/api/v1/auth/me")).andExpect(status().isUnauthorized());
        account(true);
        var login = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ada@myumanitoba.ca\",\"password\":\"password\"}"))
                .andExpect(status().isOk()).andReturn();
        var session = (MockHttpSession) login.getRequest().getSession(false);
        assertNotNull(session);
        mvc.perform(get("/api/v1/auth/me").session(session))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value("ada@myumanitoba.ca"))
                .andExpect(jsonPath("$.firstName").value("Ada"))
                .andExpect(jsonPath("$.email").value("ada@myumanitoba.ca"))
                .andExpect(jsonPath("$.verified").value(true))
                .andExpect(jsonPath("$.password").doesNotExist());
    }
    @Test
    void verifiedLoginSkipsEmail() throws Exception {
        account(true);
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ada@myumanitoba.ca\",\"password\":\"password\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.user.verified").value(true));
        verifyNoInteractions(verification);
    }

    @Test
    void currentUserRejectsDeletedAccount() throws Exception {
        account(true);
        var session = loginSession();
        when(users.findByEmail("ada@myumanitoba.ca")).thenReturn(Optional.empty());
        mvc.perform(get("/api/v1/auth/me").session(session))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void currentUserReturnsUnverifiedAccountWithoutSendingAnotherCode() throws Exception {
        account(false);
        var session = loginSession();
        clearInvocations(verification);
        mvc.perform(get("/api/v1/auth/me").session(session))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("ada@myumanitoba.ca"))
                .andExpect(jsonPath("$.verified").value(false));
        verifyNoInteractions(verification);
    }

    @Test
    void currentUserReadsUpdatedAccountDetailsAfterLogin() throws Exception {
        account(false);
        var session = loginSession();
        var updated = new User("ada@myumanitoba.ca", "secret", "Updated", "Name", true);
        when(users.findByEmail(updated.getEmail())).thenReturn(Optional.of(updated));
        mvc.perform(get("/api/v1/auth/me").session(session))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(updated.getEmail()))
                .andExpect(jsonPath("$.firstName").value("Updated"))
                .andExpect(jsonPath("$.lastName").value("Name"))
                .andExpect(jsonPath("$.verified").value(true))
                .andExpect(jsonPath("$.password").doesNotExist());
    }

    private MockHttpSession loginSession() throws Exception {
        var result = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ada@myumanitoba.ca\",\"password\":\"password\"}"))
                .andExpect(status().isOk()).andReturn();
        var session = (MockHttpSession) result.getRequest().getSession(false);
        assertNotNull(session);
        return session;
    }

    @Test
    void wrongPasswordAndUnknownUserAreUnauthorized() throws Exception {
        account(false);
        for (String email : new String[]{"ada@myumanitoba.ca", "unknown@myumanitoba.ca"}) {
            var result = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                            .content("{\"email\":\"" + email + "\",\"password\":\"wrong\"}"))
                    .andExpect(status().isUnauthorized()).andReturn();
            assertNull(result.getRequest().getSession(false));
        }
        verifyNoInteractions(verification);
    }

    @Test
    void deliveryFailureIsReportedAndLoginCanRetry() throws Exception {
        account(false);
        doThrow(new MailSendException("SMTP unavailable")).doNothing()
                .when(verification).sendVerificationCode("ada@myumanitoba.ca");
        var login = post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"ada@myumanitoba.ca\",\"password\":\"password\"}");
        mvc.perform(login).andExpect(status().isServiceUnavailable());
        mvc.perform(login).andExpect(status().isOk());
        verify(users, never()).deleteByEmail(anyString());
    }
}

