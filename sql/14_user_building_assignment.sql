-- 14_user_building_assignment.sql
-- Optional building-level assignment for staff users inside multi-structure communities.

SET search_path TO lazaro, public;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS building_id BIGINT REFERENCES buildings(id);

CREATE INDEX IF NOT EXISTS idx_users_building ON users(building_id);
