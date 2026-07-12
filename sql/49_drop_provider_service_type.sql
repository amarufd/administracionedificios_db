-- ============================================================
-- Migration 49: elimina service_type de providers
-- La clasificación de servicio queda a cargo de provider_categories
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE providers
    DROP COLUMN IF EXISTS service_type;
