package com.gobison.backend.features.rides.application;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.DayOfWeek;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

final class RideDays {
    private RideDays() {}

    static void validate(List<DayOfWeek> days, List<Set<DayOfWeek>> previous) {
        for (var day : days) {
            if (isWeekend(day) && previous.stream().noneMatch(leg -> leg.contains(day))) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "New ride days must be Monday to Friday");
            }
        }
    }

    static Set<DayOfWeek> forLeg(List<DayOfWeek> days, Set<DayOfWeek> previous) {
        var selected = EnumSet.copyOf(days);
        selected.removeIf(day -> isWeekend(day) && !previous.contains(day));
        if (selected.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose at least one day for each leg");
        }
        return selected;
    }

    private static boolean isWeekend(DayOfWeek day) {
        return day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY;
    }
}
