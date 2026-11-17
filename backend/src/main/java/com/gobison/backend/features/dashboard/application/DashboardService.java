package com.gobison.backend.features.dashboard.application;

import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
import com.gobison.backend.features.dashboard.domain.repository.RideAgreementSummaryRepository;
import org.springframework.stereotype.Service;
 
import java.util.List;
import java.util.Locale;
 
@Service
public class DashboardService {
 
    private final RideAgreementSummaryRepository agreements;
 
    public DashboardService(RideAgreementSummaryRepository agreements) {
        this.agreements = agreements;
    }
 
    public List<RideAgreementSummary> getAgreementsFor(String email) {
        return agreements.findByMemberEmail(email.trim().toLowerCase(Locale.ROOT));
    }
}
 