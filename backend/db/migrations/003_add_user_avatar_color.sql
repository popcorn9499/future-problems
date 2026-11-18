ALTER TABLE users
    ADD COLUMN IF NOT EXISTS avatar_color VARCHAR(7);

UPDATE users
SET avatar_color = '#E9DFD2'
WHERE avatar_color IS NULL;

ALTER TABLE users
    ALTER COLUMN avatar_color SET DEFAULT '#E9DFD2',
    ALTER COLUMN avatar_color SET NOT NULL;
