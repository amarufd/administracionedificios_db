-- ============================================================
-- Migration 05: Autenticación y rol Super Admin
-- ============================================================
SET search_path TO lazaro, public;

-- Permitir condominium_id NULL (para SUPER_ADMIN sin edificio)
ALTER TABLE users ALTER COLUMN condominium_id DROP NOT NULL;

-- Ampliar el CHECK de rol para incluir SUPER_ADMIN
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('ADMIN','CONSERJE','RESIDENTE','SUPER_ADMIN'));

-- Columna password (plain text para esta etapa; reemplazar con bcrypt en producción)
ALTER TABLE users ADD COLUMN IF NOT EXISTS password VARCHAR(128) NOT NULL DEFAULT 'admin123';

-- Ajustar el UNIQUE para que tolere NULL en condominium_id
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_condominium_id_email_key;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_condo_email
    ON users (condominium_id, email)
    WHERE condominium_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_superadmin
    ON users (email)
    WHERE condominium_id IS NULL;

-- Super Admin de plataforma (sin condominium_id)
INSERT INTO users (id, condominium_id, full_name, email, role, password)
VALUES (100, NULL, 'Super Administrador', 'superadmin@plataforma.cl', 'SUPER_ADMIN', 'super123')
ON CONFLICT DO NOTHING;

-- Actualizar passwords de usuarios seed
UPDATE users SET password = 'admin123'     WHERE email = 'admin@lazaro.cl';
UPDATE users SET password = 'conserje123'  WHERE email = 'conserje@lazaro.cl';
UPDATE users SET password = 'residente123' WHERE email = 'rocio@lazaro.cl';
