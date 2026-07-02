-- ============================================================
-- Migration 42: url origen del avatar de usuario
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS avatar_source_url TEXT;
