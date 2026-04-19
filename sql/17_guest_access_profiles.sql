SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS guest_access_profiles (
    id                  BIGSERIAL PRIMARY KEY,
    condominium_id      BIGINT NOT NULL REFERENCES condominiums(id),
    unit_id             BIGINT NOT NULL REFERENCES units(id),
    resident_user_id    BIGINT NOT NULL REFERENCES users(id),
    visitor_name        VARCHAR(120) NOT NULL,
    visitor_document    VARCHAR(60),
    is_frequent         BOOLEAN NOT NULL DEFAULT FALSE,
    access_status       VARCHAR(20) NOT NULL CHECK (access_status IN ('AUTORIZADO', 'BLOQUEADO')),
    notes               TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_guest_access_profiles_unit
    ON guest_access_profiles(condominium_id, unit_id, resident_user_id);

CREATE INDEX IF NOT EXISTS idx_guest_access_profiles_lookup
    ON guest_access_profiles(condominium_id, access_status, visitor_name);

INSERT INTO guest_access_profiles (
    condominium_id, unit_id, resident_user_id, visitor_name, visitor_document,
    is_frequent, access_status, notes
)
SELECT *
FROM (
    VALUES
        (1::BIGINT, 1::BIGINT, 3::BIGINT, 'Claudia Fuentes', '15.444.333-2', TRUE, 'AUTORIZADO', 'Hermana de la residente. Puede ingresar directamente.'),
        (1::BIGINT, 1::BIGINT, 3::BIGINT, 'Pedro Soto', '12.111.888-9', FALSE, 'BLOQUEADO', 'No permitir ingreso sin confirmacion expresa de la residente.')
) AS seed(condominium_id, unit_id, resident_user_id, visitor_name, visitor_document, is_frequent, access_status, notes)
WHERE NOT EXISTS (
    SELECT 1
    FROM guest_access_profiles gap
    WHERE gap.condominium_id = seed.condominium_id
      AND gap.unit_id = seed.unit_id
      AND gap.resident_user_id = seed.resident_user_id
      AND gap.visitor_name = seed.visitor_name
);
