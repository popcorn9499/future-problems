package com.gobison.backend.features.rides.presentation;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;

import java.time.DayOfWeek;
import java.util.List;

public record CreateRideOfferRequest(
        @NotBlank
        @Size(max = 255)
        String city,

        @NotBlank
        @Size(max = 255)
        String streetAddress,

        @NotNull
        @Pattern(regexp = "(?:[01][0-9]|2[0-3]):[0-5][0-9]")
        String arrivalTime,

        @NotEmpty
        List<@NotNull DayOfWeek> daysOfWeek,

        String description,

        @NotNull
        @Min(1)
        Integer passengerNum,

        Boolean askingForDrivers) {
}
