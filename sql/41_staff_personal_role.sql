-- ============================================================
-- Migration 41: rol personal de staff
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS staff_position VARCHAR(80);

ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users
    ADD CONSTRAINT users_role_check
    CHECK (role IN ('ADMIN','CONSERJE','RESIDENTE','MESA_DIRECTIVA','SUPER_ADMIN','PERSONAL'));
