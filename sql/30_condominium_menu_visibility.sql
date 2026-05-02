SET search_path TO lazaro, public;

ALTER TABLE condominiums
    ADD COLUMN IF NOT EXISTS show_storage_menu BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS show_parking_menu BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS show_bike_parking_menu BOOLEAN NOT NULL DEFAULT TRUE;

