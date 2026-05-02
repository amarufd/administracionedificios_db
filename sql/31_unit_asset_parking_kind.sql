SET search_path TO lazaro, public;

ALTER TABLE unit_assets
    ADD COLUMN IF NOT EXISTS parking_kind VARCHAR(20) DEFAULT 'RESIDENCIAL';

UPDATE unit_assets
SET parking_kind = 'RESIDENCIAL'
WHERE asset_type = 'ESTACIONAMIENTO'
  AND parking_kind IS NULL;

UPDATE unit_assets
SET parking_kind = NULL
WHERE asset_type <> 'ESTACIONAMIENTO';

ALTER TABLE unit_assets
    DROP CONSTRAINT IF EXISTS chk_unit_assets_parking_kind;

ALTER TABLE unit_assets
    ADD CONSTRAINT chk_unit_assets_parking_kind CHECK (
        parking_kind IS NULL OR parking_kind IN ('RESIDENCIAL', 'VISITA')
    );
