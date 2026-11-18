package com.gobison.backend.features.user.application;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.features.user.presentation.dto.UpdateProfileRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.util.function.Consumer;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class UpdateProfileServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final UpdateProfileService service = new UpdateProfileService(userRepository);

    @Test
    void updatesOnlyProvidedFieldsAndReturnsSavedUser() {
        User user = new User("ada@myumanitoba.ca", "hash", "Ada", "Lovelace", true);
        user.setAge(36);
        user.setGender("Female");
        user.setDescription("Original description");
        user.setAvatarColor("#E9DFD2");
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setFirstName("Augusta");
        request.setAvatarColor("#123ABC");
        when(userRepository.update(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User updated = service.updateProfile(user, request);

        assertSame(user, updated);
        assertAll(
                () -> assertEquals("Augusta", updated.getFirstName()),
                () -> assertEquals("Lovelace", updated.getLastName()),
                () -> assertEquals(36, updated.getAge()),
                () -> assertEquals("Female", updated.getGender()),
                () -> assertEquals("Original description", updated.getDescription()),
                () -> assertEquals("#123ABC", updated.getAvatarColor())
        );
        verify(userRepository).update(user);
    }

    @ParameterizedTest
    @MethodSource("nullOrBlankStringFields")
    void rejectsSuppliedStringFieldsThatAreNullOrBlank(
            String field,
            Consumer<UpdateProfileRequest> setInvalidValue) {
        User user = new User("ada@myumanitoba.ca", "hash", "Ada", "Lovelace", true);
        UpdateProfileRequest request = new UpdateProfileRequest();
        setInvalidValue.accept(request);

        FieldBlankException exception = assertThrows(
                FieldBlankException.class,
                () -> service.updateProfile(user, request)
        );

        assertEquals(field, exception.getField());
        verifyNoInteractions(userRepository);
    }

    @Test
    void rejectsAgeWhenExplicitlySetToNull() {
        User user = new User("ada@myumanitoba.ca", "hash", "Ada", "Lovelace", true);
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setAge(null);

        FieldBlankException exception = assertThrows(
                FieldBlankException.class,
                () -> service.updateProfile(user, request)
        );

        assertEquals("age", exception.getField());
        verifyNoInteractions(userRepository);
    }

    private static Stream<Arguments> nullOrBlankStringFields() {
        return Stream.of(
                Arguments.of(
                        "avatarColor", (Consumer<UpdateProfileRequest>) request -> request.setAvatarColor(null)),
                Arguments.of(
                        "avatarColor", (Consumer<UpdateProfileRequest>) request -> request.setAvatarColor("  ")),
                Arguments.of(
                        "description", (Consumer<UpdateProfileRequest>) request -> request.setDescription(null)),
                Arguments.of(
                        "description", (Consumer<UpdateProfileRequest>) request -> request.setDescription("  ")),
                Arguments.of(
                        "firstName", (Consumer<UpdateProfileRequest>) request -> request.setFirstName(null)),
                Arguments.of(
                        "firstName", (Consumer<UpdateProfileRequest>) request -> request.setFirstName("  ")),
                Arguments.of(
                        "lastName", (Consumer<UpdateProfileRequest>) request -> request.setLastName(null)),
                Arguments.of(
                        "lastName", (Consumer<UpdateProfileRequest>) request -> request.setLastName("  ")),
                Arguments.of(
                        "gender", (Consumer<UpdateProfileRequest>) request -> request.setGender(null)),
                Arguments.of(
                        "gender", (Consumer<UpdateProfileRequest>) request -> request.setGender("  "))
        );
    }
}
