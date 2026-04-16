-- 13_buildings.sql
-- Intermediate entity between condominiums and units for multi-structure communities.
-- A building represents a tower, house block, or commercial zone within a condominium.

SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS buildings (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    name                VARCHAR(120) NOT NULL,
    building_type       VARCHAR(30) NOT NULL CHECK (
        building_type IN ('EDIFICIO', 'CASA', 'LOCAL_COMERCIAL', 'BLOQUE', 'PARCELA')
    ),
    floors              INT,
    address             VARCHAR(255),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (condominium_id, name)
);

CREATE INDEX IF NOT EXISTS idx_buildings_condominium ON buildings(condominium_id);

-- Optional FK from units to buildings (nullable for single-building communities)
ALTER TABLE units
    ADD COLUMN IF NOT EXISTS building_id BIGINT REFERENCES buildings(id);

CREATE INDEX IF NOT EXISTS idx_units_building ON units(building_id);
