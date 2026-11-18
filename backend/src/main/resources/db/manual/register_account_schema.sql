ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email varchar(254),
    ADD COLUMN IF NOT EXISTS created_at timestamptz;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = to_regclass('users')
          AND attname = 'um_net_id'
          AND NOT attisdropped
    ) THEN
        EXECUTE $sql$
            UPDATE users
            SET email = lower(um_net_id) || '@myumanitoba.ca'
            WHERE email IS NULL OR btrim(email) = ''
        $sql$;
    ELSIF EXISTS (
        SELECT 1
        FROM users
        WHERE email IS NULL OR btrim(email) = ''
    ) THEN
        RAISE EXCEPTION
            'Cannot populate users.email: um_net_id is absent and one or more email values are missing';
    END IF;
END
$$;

UPDATE users
SET created_at = now()
WHERE created_at IS NULL;

ALTER TABLE users
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN created_at SET DEFAULT now(),
    ALTER COLUMN created_at SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users (email);
