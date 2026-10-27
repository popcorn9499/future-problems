package com.gobison.backend.features.auth.infrastructure.email;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class EmailServiceTest {

    @Test
    void sendsPlainTextCodeWithConfiguredSenderAndRecipient() {
        JavaMailSender sender = mock(JavaMailSender.class);
        EmailService service = new EmailService(sender, "gobison@example.com");
        ArgumentCaptor<SimpleMailMessage> message = ArgumentCaptor.forClass(SimpleMailMessage.class);

        service.sendVerificationCode("jsmith@myumanitoba.ca", "000042");

        verify(sender).send(message.capture());
        assertEquals("gobison@example.com", message.getValue().getFrom());
        assertArrayEquals(new String[]{"jsmith@myumanitoba.ca"}, message.getValue().getTo());
        assertEquals("GoBison Verification Code", message.getValue().getSubject());
        assertEquals("Your GoBison verification code is: 000042", message.getValue().getText());
    }

    @Test
    void propagatesSmtpFailureToCaller() {
        JavaMailSender sender = mock(JavaMailSender.class);
        EmailService service = new EmailService(sender, "gobison@example.com");
        doThrow(new MailSendException("SMTP unavailable")).when(sender).send(any(SimpleMailMessage.class));

        assertThrows(MailSendException.class,
                () -> service.sendVerificationCode("jsmith@myumanitoba.ca", "483921"));
    }
}
