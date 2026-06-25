-- ============================================================
-- Migration 45: fondos configurables por comunidad
-- ============================================================
SET search_path TO lazaro, public;

CREATE TABLE funds (
    id BIGSERIAL PRIMARY KEY,
    condominium_id BIGINT NOT NULL REFERENCES condominiums(id),
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo_recaudacion VARCHAR(20) NOT NULL CHECK (tipo_recaudacion IN ('FIJO', 'PORCENTAJE')),
    monto_mensual NUMERIC(12,2),
    porcentaje NUMERIC(5,2),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_funds_condominium ON funds(condominium_id);
