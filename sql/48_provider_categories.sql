-- ============================================================
-- Migration 48: categorías de proveedores por condominio
-- ============================================================
SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS provider_categories (
    id BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    name VARCHAR(120) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_provider_categories_condo_name
    ON provider_categories(condominium_id, name);

CREATE INDEX IF NOT EXISTS idx_provider_categories_condominium
    ON provider_categories(condominium_id);

ALTER TABLE providers
    ADD COLUMN IF NOT EXISTS category_id BIGINT
        REFERENCES provider_categories(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_providers_category
    ON providers(category_id) WHERE category_id IS NOT NULL;
