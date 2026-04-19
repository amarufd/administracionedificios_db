SET search_path TO lazaro, public;

ALTER TABLE units
    DROP CONSTRAINT IF EXISTS units_condominium_id_code_key;

DROP INDEX IF EXISTS idx_units_condo_code_without_building;
CREATE UNIQUE INDEX IF NOT EXISTS idx_units_condo_code_without_building
    ON units(condominium_id, code)
    WHERE building_id IS NULL;

DROP INDEX IF EXISTS idx_units_building_code;
CREATE UNIQUE INDEX IF NOT EXISTS idx_units_building_code
    ON units(building_id, code)
    WHERE building_id IS NOT NULL;
