-- ============================================================
-- Migration 07: Normalizar tipos de comunidad
-- ============================================================
SET search_path TO lazaro, public;

UPDATE condominiums
SET condominium_type = CASE condominium_type
    WHEN 'EDIFICIO' THEN 'EDIFICIO_RESIDENCIAL'
    WHEN 'CASAS' THEN 'CONDOMINIO_CASAS'
    WHEN 'PARCELAS' THEN 'CONDOMINIO_PARCELAS'
    WHEN 'OFICINAS' THEN 'OFICINA_OFICINAS'
    WHEN 'MIXTO' THEN 'CONDOMINIO_RES_COMERCIAL'
    ELSE condominium_type
END
WHERE condominium_type IN ('EDIFICIO', 'CASAS', 'PARCELAS', 'OFICINAS', 'MIXTO');

ALTER TABLE condominiums
    DROP CONSTRAINT IF EXISTS chk_condominiums_condominium_type;

ALTER TABLE condominiums
    ADD CONSTRAINT chk_condominiums_condominium_type CHECK (
        condominium_type IS NULL OR condominium_type IN (
            'EDIFICIO_RESIDENCIAL',
            'EDIFICIO_USO_MIXTO',
            'CONDOMINIO_CASAS',
            'CONDOMINIO_PARCELAS',
            'CONDOMINIO_EDIFICIOS',
            'CONDOMINIO_RES_COMERCIAL',
            'OFICINA_OFICINAS',
            'OFICINA_CON_COMERCIO'
        )
    );
