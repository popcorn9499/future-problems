ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email varchar(254),
    ADD COLUMN IF NOT EXISTS user_id varchar(40),
    ADD COLUMN IF NOT EXISTS created_at timestamptz;

UPDATE users
SET email = lower(um_net_id) || '@myumanitoba.ca'
WHERE email IS NULL OR btrim(email) = '';

UPDATE users
SET user_id = 'usr_' || replace(gen_random_uuid()::text, '-', '')
WHERE user_id IS NULL;

UPDATE users
SET created_at = now()
WHERE created_at IS NULL;

ALTER TABLE users
    ALTER COLUMN email SET NOT NULL,
    ALTER COLUMN user_id SET NOT NULL,
    ALTER COLUMN created_at SET DEFAULT now(),
    ALTER COLUMN created_at SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users (email);
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_user_id ON users (user_id);
