-- ============================================================
-- Migration 36: tipo de objeto recibido en conserjeria
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE parcels
    ADD COLUMN IF NOT EXISTS parcel_type VARCHAR(30) NOT NULL DEFAULT 'ENCOMIENDA';

ALTER TABLE parcels DROP CONSTRAINT IF EXISTS parcels_parcel_type_check;
ALTER TABLE parcels ADD CONSTRAINT parcels_parcel_type_check
    CHECK (parcel_type IN ('ENCOMIENDA','DELIVERY','VIVERES'));

UPDATE parcels
SET parcel_type = 'ENCOMIENDA'
WHERE parcel_type IS NULL;
