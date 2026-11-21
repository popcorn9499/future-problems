package com.gobison.backend.features.rides;

import com.gobison.backend.features.rides.application.RideWriter;
import com.gobison.backend.features.rides.domain.model.RideOffer;
import com.gobison.backend.features.rides.domain.model.RideRequest;
import com.gobison.backend.features.rides.domain.repository.RideOfferRepository;
import com.gobison.backend.features.rides.domain.repository.RideRequestRepository;
import com.gobison.backend.features.user.domain.model.User;
import com.gobison.backend.features.user.domain.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.AnnotationTransactionAttributeSource;
import org.springframework.transaction.interceptor.TransactionInterceptor;
import org.springframework.transaction.support.SimpleTransactionStatus;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.any;

class RideWriterTransactionTest {
    @Test
    void bothFlowsCommitOnceOrRollBackTheWholePair() {
        for (boolean offer : new boolean[] {false, true}) {
            for (boolean fail : new boolean[] {false, true}) {
                var requests = mock(RideRequestRepository.class);
                var offers = mock(RideOfferRepository.class);
                var users = mock(UserRepository.class);
                var email = "ada@myumanitoba.ca";
                when(users.lockActiveByEmail(email))
                        .thenReturn(Optional.of(new User(email, "secret", "Ada", "Lovelace", true)));
                var transactions = mock(PlatformTransactionManager.class);
                var status = new SimpleTransactionStatus();
                when(transactions.getTransaction(any())).thenReturn(status);
                var interceptor = new TransactionInterceptor();
                interceptor.setTransactionManager(transactions);
                interceptor.setTransactionAttributeSource(new AnnotationTransactionAttributeSource());
                var factory = new ProxyFactory(new RideWriter(requests, offers, users));
                factory.addAdvice(interceptor);
                var writer = (RideWriter) factory.getProxy();
                if (offer) {
                    var first = mock(RideOffer.class);
                    var second = mock(RideOffer.class);
                    when(first.getUserId()).thenReturn(email);
                    when(offers.create(first)).thenReturn(first);
                    if (fail) when(offers.create(second)).thenThrow(new IllegalStateException("write failed"));
                    else when(offers.create(second)).thenReturn(second);
                    if (fail) assertThrows(IllegalStateException.class, () -> writer.saveOffers(List.of(first, second)));
                    else assertEquals(List.of(first, second), writer.saveOffers(List.of(first, second)));
                } else {
                    var first = mock(RideRequest.class);
                    var second = mock(RideRequest.class);
                    when(first.getUserId()).thenReturn(email);
                    when(requests.create(first)).thenReturn(first);
                    if (fail) when(requests.create(second)).thenThrow(new IllegalStateException("write failed"));
                    else when(requests.create(second)).thenReturn(second);
                    if (fail) assertThrows(IllegalStateException.class, () -> writer.saveRequests(List.of(first, second)));
                    else assertEquals(List.of(first, second), writer.saveRequests(List.of(first, second)));
                }
                verify(transactions, times(1)).getTransaction(any());
                if (fail) {
                    verify(transactions).rollback(status);
                    verify(transactions, never()).commit(any());
                } else {
                    verify(transactions).commit(status);
                    verify(transactions, never()).rollback(any());
                }
            }
        }
    }
}
