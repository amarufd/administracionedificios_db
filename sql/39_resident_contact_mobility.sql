-- ============================================================
-- Migration 39: contacto y movilidad de residentes
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS secondary_email VARCHAR(180);

ALTER TABLE units
    ADD COLUMN IF NOT EXISTS needs_mobility_assistance BOOLEAN NOT NULL DEFAULT FALSE;
