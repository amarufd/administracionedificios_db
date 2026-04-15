ALTER TABLE lazaro.incidents
    ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS resolution_notes TEXT;
