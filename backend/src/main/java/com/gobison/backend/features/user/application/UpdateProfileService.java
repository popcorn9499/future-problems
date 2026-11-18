package com.gobison.backend.features.user.application;

import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import com.gobison.backend.features.user.presentation.dto.UpdateProfileRequest;
import org.springframework.stereotype.Service;

@Service
public class UpdateProfileService {

    private final UserRepository userRepository;

    public UpdateProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }


    public User updateProfile(User user, UpdateProfileRequest request) {
        if (request.hasAge() && request.getAge() == null) {
            throw new FieldBlankException("age");
        }
        requireNotBlank(request.hasAvatarColor(), request.getAvatarColor(), "avatarColor");
        requireNotBlank(request.hasDescription(), request.getDescription(), "description");
        requireNotBlank(request.hasFirstName(), request.getFirstName(), "firstName");
        requireNotBlank(request.hasLastName(), request.getLastName(), "lastName");
        requireNotBlank(request.hasGender(), request.getGender(), "gender");

        if (request.hasAge()) user.setAge(request.getAge());
        if (request.hasAvatarColor()) user.setAvatarColor(request.getAvatarColor());
        if (request.hasDescription()) user.setDescription(request.getDescription());
        if (request.hasFirstName()) user.setFirstName(request.getFirstName());
        if (request.hasLastName()) user.setLastName(request.getLastName());
        if (request.hasGender()) user.setGender(request.getGender());

        return userRepository.update(user);
    }

    private void requireNotBlank(boolean supplied, String value, String field) {
        if (supplied && (value == null || value.isBlank())) {
            throw new FieldBlankException(field);
        }
    }
}
