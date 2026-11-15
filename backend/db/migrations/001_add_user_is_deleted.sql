ALTER TABLE users
    ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN;

UPDATE users
SET is_deleted = FALSE
WHERE is_deleted IS NULL;

ALTER TABLE users
    ALTER COLUMN is_deleted SET DEFAULT FALSE,
    ALTER COLUMN is_deleted SET NOT NULL;
