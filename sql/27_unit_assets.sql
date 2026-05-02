SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS unit_assets (
    id                         BIGSERIAL PRIMARY KEY,
    condominium_id             BIGINT NOT NULL REFERENCES condominiums(id),
    building_id                BIGINT NOT NULL REFERENCES buildings(id),
    unit_id                    BIGINT REFERENCES units(id),
    asset_type                 VARCHAR(30) NOT NULL CHECK (asset_type IN ('BODEGA', 'ESTACIONAMIENTO', 'BICICLETERO')),
    code                       VARCHAR(40) NOT NULL,
    location                   VARCHAR(160),
    proration                  VARCHAR(30),
    tax_role                   VARCHAR(60),
    developer_delivery_date    DATE,
    license_plate              VARCHAR(20),
    second_license_plate       VARCHAR(20),
    observations               TEXT,
    brand                      VARCHAR(80),
    model                      VARCHAR(80),
    color                      VARCHAR(60),
    parking_kind               VARCHAR(20) DEFAULT 'RESIDENCIAL' CHECK (
        parking_kind IS NULL OR parking_kind IN ('RESIDENCIAL', 'VISITA')
    ),
    created_at                 TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, asset_type, code)
);

CREATE INDEX IF NOT EXISTS idx_unit_assets_condo_type
    ON unit_assets(condominium_id, asset_type, code);

CREATE INDEX IF NOT EXISTS idx_unit_assets_building
    ON unit_assets(building_id, asset_type);

CREATE INDEX IF NOT EXISTS idx_unit_assets_unit
    ON unit_assets(unit_id, asset_type)
    WHERE unit_id IS NOT NULL;
