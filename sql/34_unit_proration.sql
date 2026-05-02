SET search_path TO lazaro, public;

ALTER TABLE units
    ADD COLUMN IF NOT EXISTS proration VARCHAR(20);
