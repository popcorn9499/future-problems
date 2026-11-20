package com.gobison.backend.features.livechat.domain.model;

import java.time.Instant;
import java.util.List;

public class Conversation {
    private final String id;
    private final List<String> participants;
    private final Instant createdAt;

    public Conversation(String id, List<String> participants) {
        this(id, participants, Instant.now());
    }

    public Conversation(String id, List<String> participants, Instant createdAt) {
        if (participants.size() != 2 || participants.get(0).equals(participants.get(1))) {
            throw new IllegalArgumentException("A direct conversation must have two distinct participants");
        }
        this.id = id;
        this.participants = participants.stream().sorted().toList();
        this.createdAt = createdAt;
    }

    public String getId() {
        return id;
    }

    public List<String> getParticipants() {
        return participants;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}