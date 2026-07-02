-- ============================================================
-- Migration 43: campos extendidos para proveedores
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE providers
    ADD COLUMN IF NOT EXISTS rut VARCHAR(20),
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS rating SMALLINT,
    ADD COLUMN IF NOT EXISTS is_incomplete BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS created_from_expense_id BIGINT REFERENCES common_expenses(id) ON DELETE SET NULL;

ALTER TABLE providers
    DROP CONSTRAINT IF EXISTS providers_rating_check;

ALTER TABLE providers
    ADD CONSTRAINT providers_rating_check
    CHECK (rating IS NULL OR (rating BETWEEN 1 AND 5));

CREATE UNIQUE INDEX IF NOT EXISTS uq_providers_condominium_rut
    ON providers(condominium_id, rut) WHERE rut IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_providers_incomplete
    ON providers(condominium_id, is_incomplete) WHERE is_incomplete = true;
