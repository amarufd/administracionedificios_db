ALTER TABLE users
    ADD COLUMN IF NOT EXISTS avatar_source_url TEXT;
