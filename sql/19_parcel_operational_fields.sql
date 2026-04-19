-- Migration 19: enrich parcel operational tracking for concierge workflow
SET search_path TO lazaro, public;

ALTER TABLE parcels
    ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS delivered_to_user_id BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS registered_by_user_id BIGINT REFERENCES users(id);

