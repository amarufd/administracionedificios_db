SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS visitor_parking_sessions (
    id              BIGSERIAL PRIMARY KEY,
    condominium_id  BIGINT NOT NULL REFERENCES condominiums(id),
    unit_asset_id   BIGINT NOT NULL REFERENCES unit_assets(id),
    unit_id         BIGINT NOT NULL REFERENCES units(id),
    license_plate   VARCHAR(20) NOT NULL,
    notes           TEXT,
    started_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at        TIMESTAMP,
    notified_at     TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_visitor_parking_active_asset
    ON visitor_parking_sessions(unit_asset_id)
    WHERE ended_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_visitor_parking_condo_active
    ON visitor_parking_sessions(condominium_id, ended_at, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_visitor_parking_unit
    ON visitor_parking_sessions(unit_id, started_at DESC);

INSERT INTO settings(condominium_id, key, value, description, updated_at)
SELECT c.id, 'visitor_parking_max_hours', '2', 'Horas maximas para estacionamientos de visita', NOW()
FROM condominiums c
WHERE NOT EXISTS (
    SELECT 1
    FROM settings s
    WHERE s.condominium_id = c.id
      AND s.key = 'visitor_parking_max_hours'
);

