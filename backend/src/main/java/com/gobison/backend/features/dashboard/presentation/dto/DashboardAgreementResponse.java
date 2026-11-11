package com.gobison.backend.features.dashboard.presentation.dto;

 
import com.gobison.backend.features.dashboard.domain.model.AgreementMember;
import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
 
import java.time.DayOfWeek;
import java.time.format.DateTimeFormatter;
import java.util.List;
 
public record DashboardAgreementResponse(
        Long id,
        String origin,
        String destination,
        String departureTime,
        List<DayOfWeek> daysOfWeek,
        String status,
        List<Member> drivers,
        List<Member> passengers
) {
 
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
 
    public record Member(String id, String firstName, String lastName, String address) {
 
        static Member from(AgreementMember member) {
            return new Member(member.email(), member.firstName(), member.lastName(), member.address());
        }
    }
 
    public static DashboardAgreementResponse from(RideAgreementSummary agreement) {
        return new DashboardAgreementResponse(
                agreement.id(),
                agreement.origin(),
                agreement.destination(),
                agreement.departureTime().format(TIME_FORMAT),
                agreement.daysOfWeek(),
                agreement.status(),
                agreement.drivers().stream().map(Member::from).toList(),
                agreement.passengers().stream().map(Member::from).toList()
        );
    }
}
 