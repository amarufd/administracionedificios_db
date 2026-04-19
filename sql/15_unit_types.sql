SET search_path TO lazaro, public;

ALTER TABLE units
    ADD COLUMN IF NOT EXISTS unit_type VARCHAR(30);

UPDATE units u
SET unit_type = resolved.unit_type
FROM (
    SELECT
        u.id,
        CASE
            WHEN u.code ~* '^loc-' THEN 'LOCAL_COMERCIAL'
            WHEN u.code ~* '^of-' THEN 'OFICINA'
            WHEN u.code ~* '^dep-' THEN 'DEPARTAMENTO'
            WHEN b.building_type = 'LOCAL_COMERCIAL' THEN 'LOCAL_COMERCIAL'
            WHEN c.condominium_type = 'OFICINA_OFICINAS' THEN 'OFICINA'
            WHEN c.condominium_type = 'OFICINA_CON_COMERCIO' THEN 'OFICINA'
            ELSE 'DEPARTAMENTO'
        END AS unit_type
    FROM units u
    JOIN condominiums c ON c.id = u.condominium_id
    LEFT JOIN buildings b ON b.id = u.building_id
) resolved
WHERE resolved.id = u.id
  AND (u.unit_type IS NULL OR u.unit_type NOT IN ('DEPARTAMENTO', 'LOCAL_COMERCIAL', 'OFICINA'));

ALTER TABLE units
    ALTER COLUMN unit_type SET DEFAULT 'DEPARTAMENTO';

UPDATE units
SET unit_type = 'DEPARTAMENTO'
WHERE unit_type IS NULL;

ALTER TABLE units
    ALTER COLUMN unit_type SET NOT NULL;

ALTER TABLE units
    DROP CONSTRAINT IF EXISTS chk_units_unit_type;

ALTER TABLE units
    ADD CONSTRAINT chk_units_unit_type CHECK (
        unit_type IN ('DEPARTAMENTO', 'LOCAL_COMERCIAL', 'OFICINA')
    );

WITH normalized AS (
    SELECT
        id,
        condominium_id,
        CASE unit_type
            WHEN 'LOCAL_COMERCIAL' THEN 'loc-'
            WHEN 'OFICINA' THEN 'of-'
            ELSE 'dep-'
        END || regexp_replace(code, '^(dep-|loc-|of-)', '', 'i') AS target_code
    FROM units
),
ranked AS (
    SELECT
        id,
        CASE
            WHEN row_number() OVER (PARTITION BY condominium_id, target_code ORDER BY id) = 1 THEN target_code
            ELSE target_code || '-' || id::text
        END AS final_code
    FROM normalized
)
UPDATE units u
SET code = ranked.final_code
FROM ranked
WHERE ranked.id = u.id
  AND u.code IS DISTINCT FROM ranked.final_code;
