SET search_path TO lazaro, public;

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS visitor_parking_max_hours INT NOT NULL DEFAULT 2;

UPDATE buildings
SET visitor_parking_max_hours = 2
WHERE visitor_parking_max_hours IS NULL
   OR visitor_parking_max_hours < 1;

ALTER TABLE buildings
    DROP CONSTRAINT IF EXISTS chk_buildings_visitor_parking_max_hours;

ALTER TABLE buildings
    ADD CONSTRAINT chk_buildings_visitor_parking_max_hours CHECK (visitor_parking_max_hours >= 1);

