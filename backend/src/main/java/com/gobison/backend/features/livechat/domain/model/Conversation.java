package com.gobison.backend.features.livechat.domain.model;

import java.util.List;

public class Conversation {
    private String id;
    private List<String> participants;

    public Conversation(String id, List<String> participants) {
        if (participants.size() != 2 || participants.get(0).equals(participants.get(1))) {
            throw new IllegalArgumentException("A direct conversation must have two distinct participants");
        }
        this.id = id;
        this.participants = participants.stream().sorted().toList();
    }

    public String getId() {
        return id;
    }

    public List<String> getParticipants() {
        return participants;
    }

}