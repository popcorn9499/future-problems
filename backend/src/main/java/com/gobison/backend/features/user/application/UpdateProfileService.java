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


    public UserRepository.CreateResult updateProfile(User user, UpdateProfileRequest request) {
        User updatedUser = null;
        boolean saved = false;


        // updated what is updated
        if (request.hasAge())             user.setAge(request.getAge());

        if (request.hasAvatarColor())
            user.setAvatarColor(request.getAvatarColor());

        if (request.hasDescription())
            user.setDescription(request.getDescription());

        if (request.hasFirstName())
            user.setFirstName(request.getFirstName());

        if (request.hasLastName())
            user.setLastName(request.getLastName());

        if (request.hasGender())
            user.setGender(request.getGender());

        updatedUser = userRepository.update(user);
        saved = updatedUser != null && updatedUser.getEmail().equals(user.getEmail());
        return new UserRepository.CreateResult(user, saved);
    }
}
