package com.gobison.backend.features.dashboard.domain.repository;

import com.gobison.backend.features.dashboard.domain.model.RideAgreementSummary;
 
import java.util.List;
 
public interface RideAgreementSummaryRepository {
 
    /** Every agreement in which the given user is a driver or a passenger. */
    List<RideAgreementSummary> findByMemberEmail(String email);
}