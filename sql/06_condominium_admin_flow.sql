-- ============================================================
-- Migration 06: Admin principal y metadatos del condominio
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE condominiums
    ADD COLUMN IF NOT EXISTS condominium_type VARCHAR(30),
    ADD COLUMN IF NOT EXISTS admin_user_id BIGINT REFERENCES users(id);

CREATE INDEX IF NOT EXISTS idx_condominiums_admin_user_id
    ON condominiums(admin_user_id);

UPDATE condominiums c
SET admin_user_id = u.id
FROM users u
WHERE u.condominium_id = c.id
  AND u.role = 'ADMIN'
  AND c.admin_user_id IS NULL;
