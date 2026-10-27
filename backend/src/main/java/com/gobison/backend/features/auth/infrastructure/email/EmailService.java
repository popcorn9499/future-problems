package com.gobison.backend.features.auth.infrastructure.email;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;
    private final String senderAddress;
    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    public EmailService(JavaMailSender mailSender, @Value("${gobison.mail.from}") String senderAddress) {
        this.mailSender = mailSender;
        this.senderAddress = senderAddress;
    }

    public void sendVerificationCode(String recipient, String code) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(senderAddress);
            message.setTo(recipient);
            message.setSubject("GoBison Verification Code");
            message.setText("Your GoBison verification code is: " + code);

            mailSender.send(message);
            logger.info("Verification code email successfully sent to recipient: {}", recipient);

        } catch (MailException e) {
            logger.error("Failed to send verification code email to recipient: {}. Reason: {}", recipient, e.getMessage(), e);
            throw e;
        }
    }
}
