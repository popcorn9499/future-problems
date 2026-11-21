package com.gobison.backend.features.user.presentation;

import com.gobison.backend.features.user.application.DeleteAccountService;

import com.gobison.backend.features.user.application.FieldBlankException;
import com.gobison.backend.features.user.application.UpdateProfileService;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.features.user.presentation.dto.UpdateProfileRequest;
import com.gobison.backend.security.SecurityConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = UserAccountController.class, properties = "spring.config.import=")
@Import({SecurityConfiguration.class, UserProfileExceptionHandler.class})
class UserAccountControllerTest {
    @MockitoBean
    private DeleteAccountService deleteAccountService;


    private static final String ENDPOINT = "/api/v1/users/me/profile";
    private static final String EMAIL = "ada@myumanitoba.ca";

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private UserRepository users;

    @MockitoBean
    private UpdateProfileService updateProfileService;

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
        user.setPronouns("Female");
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

    @Test
    void patchRequiresAuthentication() throws Exception {
        mvc.perform(patch(ENDPOINT)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Augusta\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(users, updateProfileService);
    }

    @Test
    void updatesAuthenticatedUsersProfileAndReturnsUpdatedProfile() throws Exception {
        User existing = new User(EMAIL, "password-hash", "Ada", "Lovelace", true);
        when(users.findByEmail(EMAIL)).thenReturn(Optional.of(existing));

        User updated = new User(EMAIL, "password-hash", "Augusta", "Byron", true);
        updated.setAge(36);
        updated.setPronouns("Female");
        updated.setDescription("Mathematician");
        updated.setAvatarColor("#123ABC");
        when(updateProfileService.updateProfile(
                eq(existing),
                any(UpdateProfileRequest.class)))
                .thenReturn(updated);

        mvc.perform(patch(ENDPOINT).with(user(EMAIL))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Augusta\",\"avatarColor\":\"#123ABC\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(EMAIL))
                .andExpect(jsonPath("$.firstName").value("Augusta"))
                .andExpect(jsonPath("$.lastName").value("Byron"))
                .andExpect(jsonPath("$.age").value(36))
                .andExpect(jsonPath("$.gender").value("Female"))
                .andExpect(jsonPath("$.description").value("Mathematician"))
                .andExpect(jsonPath("$.avatarColor").value("#123ABC"))
                .andExpect(jsonPath("$.password").doesNotExist());

        verify(users).findByEmail(EMAIL);
        verify(updateProfileService).updateProfile(
                eq(existing),
                argThat(request ->
                        request.hasFirstName()
                                && "Augusta".equals(request.getFirstName())
                                && request.hasAvatarColor()
                                && "#123ABC".equals(request.getAvatarColor())
                                && !request.hasAge()));
    }

    @Test
    void rejectsPatchWhenAuthenticatedAccountDoesNotExist() throws Exception {
        when(users.findByEmail(EMAIL)).thenReturn(Optional.empty());

        mvc.perform(patch(ENDPOINT).with(user(EMAIL))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Augusta\"}"))
                .andExpect(status().isUnauthorized());

        verify(users).findByEmail(EMAIL);
        verifyNoInteractions(updateProfileService);
    }

    @Test
    void mapsInvalidProfileFieldToBadRequest() throws Exception {
        User existing = new User(EMAIL, "password-hash", "Ada", "Lovelace", true);
        when(users.findByEmail(EMAIL)).thenReturn(Optional.of(existing));
        when(updateProfileService.updateProfile(
                eq(existing),
                any(UpdateProfileRequest.class)))
                .thenThrow(new FieldBlankException("firstName"));

        mvc.perform(patch(ENDPOINT).with(user(EMAIL))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\" \"}"))
                .andExpect(status().isBadRequest());

        verify(updateProfileService).updateProfile(
                eq(existing),
                any(UpdateProfileRequest.class));
    }
}
