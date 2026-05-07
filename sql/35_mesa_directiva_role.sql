-- ============================================================
-- Migration 35: Rol Mesa Directiva
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('ADMIN','CONSERJE','RESIDENTE','SUPER_ADMIN','MESA_DIRECTIVA'));

INSERT INTO users (id, condominium_id, full_name, email, role, password)
VALUES (4, 1, 'Mesa Directiva', 'mesa@lazaro.cl', 'MESA_DIRECTIVA', 'mesa123')
ON CONFLICT DO NOTHING;

UPDATE users
SET password = 'mesa123'
WHERE email = 'mesa@lazaro.cl';
