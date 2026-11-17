package com.gobison.backend.features.dashboard.presentation;

 
import com.gobison.backend.features.dashboard.application.DashboardService;
import com.gobison.backend.features.dashboard.presentation.dto.DashboardAgreementResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
 
import java.security.Principal;
import java.util.List;
 
@RestController
@RequestMapping("/api/v1/dashboard")
public class DashboardController {
    private final DashboardService dashboardService;
 
    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }
 
    /** The logged-in user is identified by the session; no user id is passed in. */
    @GetMapping("/agreements")
    public List<DashboardAgreementResponse> getMyAgreements(Principal principal) {
        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        return dashboardService.getAgreementsFor(principal.getName()).stream()
                .map(DashboardAgreementResponse::from)
                .toList();
    }
}
 