-- ============================================================
-- Migration 50: detalles adicionales de proveedores
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE providers
    ADD COLUMN IF NOT EXISTS comuna VARCHAR(120),
    ADD COLUMN IF NOT EXISTS website VARCHAR(255),
    ADD COLUMN IF NOT EXISTS bank VARCHAR(120);
