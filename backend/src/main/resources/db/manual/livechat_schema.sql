CREATE TABLE IF NOT EXISTS conversations (
    conversation_id varchar(41) PRIMARY KEY,
    direct_participant_one_id varchar(254) NOT NULL REFERENCES users(email),
    direct_participant_two_id varchar(254) NOT NULL REFERENCES users(email),
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_conversations_direct_participants
        UNIQUE (direct_participant_one_id, direct_participant_two_id),
    CONSTRAINT ck_conversations_direct_participants
        CHECK (direct_participant_one_id COLLATE "C" < direct_participant_two_id COLLATE "C")
);

ALTER TABLE conversations
    ADD COLUMN IF NOT EXISTS created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
