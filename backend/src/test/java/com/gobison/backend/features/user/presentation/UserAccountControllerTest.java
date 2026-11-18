package com.gobison.backend.features.user.presentation;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = UserAccountController.class, properties = "spring.config.import=")
@Import(SecurityConfiguration.class)
class UserAccountControllerTest {

    private static final String ENDPOINT = "/api/v1/users/me/profile";
    private static final String EMAIL = "ada@myumanitoba.ca";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private UserRepository users;

    @Test
    void requiresAuthentication() throws Exception {
        mvc.perform(get(ENDPOINT))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(users);
    }

    @Test
    void returnsAuthenticatedUsersProfile() throws Exception {
        User user = new User(EMAIL, "password-hash", "Ada", "Lovelace", true);
        user.setAge(36);
        user.setGender("Female");
        user.setDescription("Mathematician");
        user.setAvatarColor("#123ABC");
        when(users.findByEmail(EMAIL)).thenReturn(Optional.of(user));

        mvc.perform(get(ENDPOINT).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(EMAIL))
                .andExpect(jsonPath("$.firstName").value("Ada"))
                .andExpect(jsonPath("$.lastName").value("Lovelace"))
                .andExpect(jsonPath("$.age").value(36))
                .andExpect(jsonPath("$.gender").value("Female"))
                .andExpect(jsonPath("$.description").value("Mathematician"))
                .andExpect(jsonPath("$.avatarColor").value("#123ABC"))
                .andExpect(jsonPath("$.password").doesNotExist());

        verify(users).findByEmail(EMAIL);
    }

    @Test
    void rejectsAuthenticatedPrincipalWithoutAnAccount() throws Exception {
        when(users.findByEmail(EMAIL)).thenReturn(Optional.empty());

        mvc.perform(get(ENDPOINT).with(user(EMAIL)))
                .andExpect(status().isUnauthorized());

        verify(users).findByEmail(EMAIL);
    }
}
