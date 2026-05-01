SET search_path TO lazaro, public;

INSERT INTO buildings(condominium_id, name, building_type, floors, address, is_active)
SELECT
    c.id,
    COALESCE(NULLIF(c.display_name, ''), c.name),
    CASE
        WHEN c.condominium_type = 'CONDOMINIO_CASAS' THEN 'CASA'
        WHEN c.condominium_type = 'CONDOMINIO_PARCELAS' THEN 'PARCELA'
        ELSE 'EDIFICIO'
    END,
    NULL,
    NULL,
    TRUE
FROM condominiums c
WHERE NOT EXISTS (
    SELECT 1
    FROM buildings b
    WHERE b.condominium_id = c.id
);

UPDATE units u
SET building_id = b.id
FROM buildings b
WHERE u.condominium_id = b.condominium_id
  AND u.building_id IS NULL
  AND (
      SELECT COUNT(*)
      FROM buildings bx
      WHERE bx.condominium_id = u.condominium_id
  ) = 1;
