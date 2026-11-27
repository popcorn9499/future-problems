package com.gobison.backend.features.user.presentation;

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

import java.time.LocalDate;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
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

    private static final String ENDPOINT = "/api/v1/users/me/profile";
    private static final String EMAIL = "ada@myumanitoba.ca";

    private static final String OTHER_EMAIL = "grace@myumanitoba.ca";
    private static final String OTHER_PROFILE = "/api/v1/users/{userId}/profile";

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
    void acceptsDateOfBirthForSomeoneWhoIsExactlyFifteen() throws Exception {
        LocalDate dateOfBirth = LocalDate.now().minusYears(15);
        User existing = new User(EMAIL, "password-hash", "Ada", "Lovelace", true);
        when(users.findByEmail(EMAIL)).thenReturn(Optional.of(existing));

        User updated = new User(EMAIL, "password-hash", "Ada", "Lovelace", true);
        updated.setDateOfBirth(dateOfBirth);
        when(updateProfileService.updateProfile(eq(existing), any(UpdateProfileRequest.class)))
                .thenReturn(updated);

        mvc.perform(patch(ENDPOINT).with(user(EMAIL))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dateOfBirth\":\"" + dateOfBirth + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dateOfBirth").value(dateOfBirth.toString()))
                .andExpect(jsonPath("$.age").value(15));

        verify(updateProfileService).updateProfile(
                eq(existing),
                argThat(request -> request.hasDateOfBirth()
                        && dateOfBirth.equals(request.getDateOfBirth())));
    }

    @Test
    void rejectsDateOfBirthForSomeoneYoungerThanFifteen() throws Exception {
        LocalDate dateOfBirth = LocalDate.now().minusYears(15).plusDays(1);

        mvc.perform(patch(ENDPOINT).with(user(EMAIL))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dateOfBirth\":\"" + dateOfBirth + "\"}"))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(users, updateProfileService);
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

    // new tests for viewing another user's profile
    @Test
    void viewingAnotherUsersProfileRequiresAuthentication() throws Exception {
        mvc.perform(get(OTHER_PROFILE, OTHER_EMAIL))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(users);
    }

    @Test
    void returnsAnotherUsersPublicProfile() throws Exception {
        User other = new User(OTHER_EMAIL, "password-hash", "Grace", "Hopper", true);
        other.setAge(40);
        other.setPronouns("She/her");
        other.setDescription("Compiler person");
        other.setAvatarColor("#123ABC");
        when(users.findByEmail(OTHER_EMAIL)).thenReturn(Optional.of(other));

        mvc.perform(get(OTHER_PROFILE, OTHER_EMAIL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(OTHER_EMAIL))
                .andExpect(jsonPath("$.firstName").value("Grace"))
                .andExpect(jsonPath("$.lastName").value("Hopper"))
                .andExpect(jsonPath("$.age").value(40))
                .andExpect(jsonPath("$.gender").value("She/her"))
                .andExpect(jsonPath("$.description").value("Compiler person"))
                .andExpect(jsonPath("$.avatarColor").value("#123ABC"))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.verified").doesNotExist());

        verify(users).findByEmail(OTHER_EMAIL);
    }

    @Test
    void returnsNullLastNameForUsersWithoutOne() throws Exception {
        User other = new User(OTHER_EMAIL, "password-hash", "Grace", "Hopper", true);
        other.setLastName(null);
        when(users.findByEmail(OTHER_EMAIL)).thenReturn(Optional.of(other));

        mvc.perform(get(OTHER_PROFILE, OTHER_EMAIL).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Grace"))
                .andExpect(jsonPath("$.lastName").isEmpty());
    }

    @Test
    void looksUpTheEmailCaseInsensitively() throws Exception {
        User other = new User(OTHER_EMAIL, "password-hash", "Grace", "Hopper", true);
        when(users.findByEmail(OTHER_EMAIL)).thenReturn(Optional.of(other));

        mvc.perform(get(OTHER_PROFILE, "Grace@MyUManitoba.CA").with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Grace"));

        verify(users).findByEmail(OTHER_EMAIL);
    }

    @Test
    void returnsNotFoundForUnknownUser() throws Exception {
        when(users.findByEmail(OTHER_EMAIL)).thenReturn(Optional.empty());

        mvc.perform(get(OTHER_PROFILE, OTHER_EMAIL).with(user(EMAIL)))
                .andExpect(status().isNotFound());
    }

    @Test
    void returnsNotFoundForDeletedAccounts() throws Exception {
        User deleted = new User(OTHER_EMAIL, "password-hash", "Grace", "Hopper", true);
        deleted.setDeleted(true);
        when(users.findByEmail(OTHER_EMAIL)).thenReturn(Optional.of(deleted));

        mvc.perform(get(OTHER_PROFILE, OTHER_EMAIL).with(user(EMAIL)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.firstName").doesNotExist());
    }

    @Test
    void ownProfilePathNotTreatedAsAnotherUsersId() throws Exception {
        User own = new User(EMAIL, "password-hash", "Ada", "Lovelace", true);
        when(users.findByEmail(EMAIL)).thenReturn(Optional.of(own));

        mvc.perform(get(ENDPOINT).with(user(EMAIL)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(EMAIL));

        verify(users).findByEmail(EMAIL);
        verify(users, never()).findByEmail("me");
    }

    @Test
    void doesNotAllowEditingAnotherUsersProfile() throws Exception {
        mvc.perform(patch(OTHER_PROFILE, OTHER_EMAIL).with(user(EMAIL))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Hacked\"}"))
                .andExpect(status().isForbidden());

        verifyNoInteractions(updateProfileService);
    }
}
