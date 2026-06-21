-- 43_common_expense_transparency.sql
-- Gastos comunes: origen, conceptos, mediciones, aprobacion, actas y auditoria.

SET search_path TO lazaro, public;

ALTER TABLE buildings
    ADD COLUMN IF NOT EXISTS has_boiler BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE audit_log
    ADD COLUMN IF NOT EXISTS ip_address INET,
    ADD COLUMN IF NOT EXISTS result VARCHAR(20) NOT NULL DEFAULT 'EXITOSO';

CREATE TABLE IF NOT EXISTS expense_imports (
    id                 BIGSERIAL PRIMARY KEY,
    condominium_id     BIGINT NOT NULL REFERENCES condominiums(id),
    building_id        BIGINT REFERENCES buildings(id),
    period_yyyymm      CHAR(6) NOT NULL CHECK (period_yyyymm ~ '^[0-9]{6}$'),
    file_name          VARCHAR(255) NOT NULL,
    content_type       VARCHAR(120) NOT NULL,
    original_content   BYTEA NOT NULL,
    sha256             CHAR(64) NOT NULL,
    uploaded_by        BIGINT REFERENCES users(id),
    uploaded_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    validation_status  VARCHAR(20) NOT NULL DEFAULT 'VALIDO'
                           CHECK (validation_status IN ('VALIDO','INVALIDO')),
    validation_details TEXT
);

CREATE INDEX IF NOT EXISTS idx_expense_imports_period
    ON expense_imports(condominium_id, period_yyyymm, uploaded_at DESC);

-- Los periodos historicos reciben un origen sintetico para mantener la nueva
-- invariante sin perder datos preexistentes.
INSERT INTO expense_imports (
    condominium_id, period_yyyymm, file_name, content_type, original_content,
    sha256, uploaded_at, validation_details
)
SELECT ce.condominium_id,
       ce.period_yyyymm,
       COALESCE(NULLIF(ce.source_file_name, ''), 'migracion-' || ce.period_yyyymm || '.csv'),
       'text/csv',
       ''::bytea,
       repeat('0', 64),
       ce.created_at,
       'Origen sintetico creado al migrar un periodo historico'
FROM common_expenses ce
WHERE NOT EXISTS (
    SELECT 1
    FROM expense_imports ei
    WHERE ei.condominium_id = ce.condominium_id
      AND ei.period_yyyymm = ce.period_yyyymm
      AND ei.uploaded_at = ce.created_at
);

ALTER TABLE common_expenses
    ADD COLUMN IF NOT EXISTS expense_import_id BIGINT REFERENCES expense_imports(id),
    ADD COLUMN IF NOT EXISTS workflow_status VARCHAR(24) NOT NULL DEFAULT 'BORRADOR',
    ADD COLUMN IF NOT EXISTS published_by_user_id BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS published_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS rejection_comments TEXT;

UPDATE common_expenses ce
SET expense_import_id = (
    SELECT id
    FROM expense_imports
    WHERE condominium_id = ce.condominium_id
      AND period_yyyymm = ce.period_yyyymm
    ORDER BY uploaded_at DESC, id DESC
    LIMIT 1
)
WHERE ce.expense_import_id IS NULL;

UPDATE common_expenses
SET workflow_status = CASE
    WHEN is_confirmed THEN 'PUBLICADO'
    WHEN approved_at IS NOT NULL THEN 'APROBADO'
    ELSE workflow_status
END
WHERE workflow_status = 'BORRADOR'
  AND (is_confirmed OR approved_at IS NOT NULL);

ALTER TABLE common_expenses
    ALTER COLUMN expense_import_id SET NOT NULL;

ALTER TABLE common_expenses DROP CONSTRAINT IF EXISTS common_expenses_workflow_status_check;
ALTER TABLE common_expenses ADD CONSTRAINT common_expenses_workflow_status_check
    CHECK (workflow_status IN ('BORRADOR','EN_REVISION','APROBADO','RECHAZADO','PUBLICADO'));

CREATE TABLE IF NOT EXISTS common_expense_concepts (
    id                    BIGSERIAL PRIMARY KEY,
    common_expense_id     BIGINT NOT NULL REFERENCES common_expenses(id) ON DELETE CASCADE,
    concept_name          VARCHAR(180) NOT NULL,
    category              VARCHAR(40) NOT NULL CHECK (category IN (
                              'ADMINISTRACION','PERSONAL','SEGURIDAD','ASEO','MANTENCION',
                              'SERVICIOS_BASICOS','AGUA_CALIENTE','CALDERA','ASCENSORES',
                              'AREAS_COMUNES','FONDO_RESERVA','GASTOS_EXTRAORDINARIOS','OTROS')),
    expense_type          VARCHAR(30) NOT NULL,
    building_amount       NUMERIC(14,2) NOT NULL CHECK (building_amount >= 0),
    unit_amount           NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (unit_amount >= 0),
    calculation_method    VARCHAR(30) NOT NULL CHECK (calculation_method IN (
                              'COEFICIENTE','CONSUMO_INDIVIDUAL','MIXTO','VALOR_FIJO',
                              'METRO_CUADRADO','ESTACIONAMIENTO','BODEGA','MANUAL','PERSONALIZADO')),
    base_percentage       NUMERIC(5,2),
    consumption_percentage NUMERIC(5,2),
    monthly_variation     NUMERIC(8,2),
    observations          TEXT,
    custom_formula        TEXT,
    created_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    CHECK (
        calculation_method <> 'MIXTO'
        OR (base_percentage IS NOT NULL AND consumption_percentage IS NOT NULL
            AND base_percentage >= 0 AND consumption_percentage >= 0
            AND base_percentage + consumption_percentage = 100)
    )
);

CREATE INDEX IF NOT EXISTS idx_common_expense_concepts_expense
    ON common_expense_concepts(common_expense_id);

CREATE TABLE IF NOT EXISTS common_expense_documents (
    id                 BIGSERIAL PRIMARY KEY,
    concept_id         BIGINT NOT NULL REFERENCES common_expense_concepts(id) ON DELETE RESTRICT,
    document_type      VARCHAR(30) NOT NULL CHECK (document_type IN (
                           'FACTURA','BOLETA','CONTRATO','COTIZACION','COMPROBANTE','ACTA','OTRO')),
    file_name          VARCHAR(255) NOT NULL,
    content_type       VARCHAR(120) NOT NULL,
    original_content   BYTEA NOT NULL,
    sha256             CHAR(64) NOT NULL,
    version_no         INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    uploaded_by        BIGINT REFERENCES users(id),
    uploaded_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (concept_id, file_name, version_no)
);

CREATE TABLE IF NOT EXISTS expense_measurement_imports (
    id                 BIGSERIAL PRIMARY KEY,
    condominium_id     BIGINT NOT NULL REFERENCES condominiums(id),
    building_id        BIGINT NOT NULL REFERENCES buildings(id),
    common_expense_id  BIGINT NOT NULL REFERENCES common_expenses(id) ON DELETE CASCADE,
    period_yyyymm      CHAR(6) NOT NULL CHECK (period_yyyymm ~ '^[0-9]{6}$'),
    file_name          VARCHAR(255) NOT NULL,
    content_type       VARCHAR(120) NOT NULL,
    original_content   BYTEA NOT NULL,
    sha256             CHAR(64) NOT NULL,
    uploaded_by        BIGINT REFERENCES users(id),
    uploaded_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS expense_approvals (
    id                 BIGSERIAL PRIMARY KEY,
    common_expense_id  BIGINT NOT NULL REFERENCES common_expenses(id) ON DELETE RESTRICT,
    action             VARCHAR(20) NOT NULL CHECK (action IN ('APROBADO','RECHAZADO')),
    resolved_by        BIGINT NOT NULL REFERENCES users(id),
    resolved_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    comments           TEXT
);

-- Un periodo puede rechazarse, corregirse y volver a revision mas de una vez.
-- Cada resolucion se conserva como parte del historial de auditoria.
ALTER TABLE expense_approvals
    DROP CONSTRAINT IF EXISTS expense_approvals_common_expense_id_action_key;

CREATE TABLE IF NOT EXISTS expense_approval_records (
    id                 BIGSERIAL PRIMARY KEY,
    common_expense_id  BIGINT NOT NULL UNIQUE REFERENCES common_expenses(id) ON DELETE RESTRICT,
    approval_id        BIGINT NOT NULL UNIQUE REFERENCES expense_approvals(id) ON DELETE RESTRICT,
    act_number         VARCHAR(60) NOT NULL UNIQUE,
    act_file_name      VARCHAR(255) NOT NULL,
    act_content        BYTEA NOT NULL,
    audit_code         VARCHAR(80) NOT NULL UNIQUE,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION validate_common_expense_boiler_rules()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    boiler_enabled BOOLEAN;
BEGIN
    IF NEW.calculation_method NOT IN ('CONSUMO_INDIVIDUAL', 'MIXTO') THEN
        RETURN NEW;
    END IF;
    SELECT COALESCE(bool_or(b.has_boiler), FALSE)
      INTO boiler_enabled
      FROM common_expenses ce
      JOIN expense_imports ei ON ei.id = ce.expense_import_id
      LEFT JOIN buildings b ON b.id = ei.building_id
     WHERE ce.id = NEW.common_expense_id;
    IF NOT boiler_enabled THEN
        RAISE EXCEPTION 'El consumo individual y el calculo mixto requieren un edificio con caldera';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_common_expense_boiler_rules ON common_expense_concepts;
CREATE TRIGGER trg_common_expense_boiler_rules
BEFORE INSERT OR UPDATE ON common_expense_concepts
FOR EACH ROW EXECUTE FUNCTION validate_common_expense_boiler_rules();

CREATE OR REPLACE FUNCTION validate_measurement_boiler_rules()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    boiler_enabled BOOLEAN;
    expense_period CHAR(6);
    expense_workflow VARCHAR(24);
    expense_condominium BIGINT;
    building_condominium BIGINT;
BEGIN
    SELECT has_boiler, condominium_id
      INTO boiler_enabled, building_condominium
      FROM buildings WHERE id = NEW.building_id;
    IF NOT COALESCE(boiler_enabled, FALSE) THEN
        RAISE EXCEPTION 'Las mediciones solo estan disponibles para edificios con caldera';
    END IF;
    SELECT period_yyyymm, condominium_id, workflow_status
      INTO expense_period, expense_condominium, expense_workflow
      FROM common_expenses WHERE id = NEW.common_expense_id;
    IF expense_period IS NULL OR expense_period <> NEW.period_yyyymm THEN
        RAISE EXCEPTION 'El periodo del archivo de mediciones no coincide con el gasto comun';
    END IF;
    IF expense_workflow NOT IN ('BORRADOR', 'RECHAZADO') THEN
        RAISE EXCEPTION 'Las mediciones no pueden modificarse después de enviar el gasto a revisión';
    END IF;
    IF expense_condominium <> NEW.condominium_id
       OR building_condominium <> NEW.condominium_id THEN
        RAISE EXCEPTION 'La medicion, el edificio y el gasto comun deben pertenecer al mismo condominio';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_measurement_boiler_rules ON expense_measurement_imports;
CREATE TRIGGER trg_measurement_boiler_rules
BEFORE INSERT OR UPDATE ON expense_measurement_imports
FOR EACH ROW EXECUTE FUNCTION validate_measurement_boiler_rules();

CREATE OR REPLACE FUNCTION protect_approved_expense_records()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Las actas de aprobacion son inmutables';
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_approval_record_update ON expense_approval_records;
CREATE TRIGGER trg_protect_approval_record_update
BEFORE UPDATE OR DELETE ON expense_approval_records
FOR EACH ROW EXECUTE FUNCTION protect_approved_expense_records();

CREATE OR REPLACE FUNCTION validate_common_expense_origin_and_publication()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    import_condominium BIGINT;
    import_period CHAR(6);
BEGIN
    SELECT condominium_id, period_yyyymm
      INTO import_condominium, import_period
      FROM expense_imports
     WHERE id = NEW.expense_import_id;
    IF import_condominium IS NULL
       OR import_condominium <> NEW.condominium_id
       OR import_period <> NEW.period_yyyymm THEN
        RAISE EXCEPTION 'El archivo de origen no corresponde al condominio y periodo del gasto comun';
    END IF;
    IF (NEW.workflow_status = 'PUBLICADO' OR NEW.is_confirmed)
       AND NOT (
           TG_OP = 'UPDATE'
           AND OLD.workflow_status = 'PUBLICADO'
           AND OLD.is_confirmed
       )
       AND NOT EXISTS (
           SELECT 1 FROM expense_approval_records ar
           WHERE ar.common_expense_id = NEW.id
       ) THEN
        RAISE EXCEPTION 'No se puede publicar un gasto comun sin aprobacion y acta';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_common_expense_origin_and_publication ON common_expenses;
CREATE CONSTRAINT TRIGGER trg_common_expense_origin_and_publication
AFTER INSERT OR UPDATE ON common_expenses
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION validate_common_expense_origin_and_publication();

CREATE INDEX IF NOT EXISTS idx_expense_approvals_expense
    ON expense_approvals(common_expense_id, resolved_at DESC);

CREATE INDEX IF NOT EXISTS idx_expense_documents_concept
    ON common_expense_documents(concept_id, uploaded_at DESC);

CREATE TABLE IF NOT EXISTS common_expense_concept_allocations (
    id          BIGSERIAL PRIMARY KEY,
    concept_id  BIGINT NOT NULL REFERENCES common_expense_concepts(id) ON DELETE CASCADE,
    unit_id     BIGINT NOT NULL REFERENCES units(id),
    amount      NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    details     TEXT,
    UNIQUE (concept_id, unit_id)
);

CREATE OR REPLACE FUNCTION allocate_common_expense_concept()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common_expense_concept_allocations(concept_id, unit_id, amount, details)
    SELECT NEW.id,
           cei.unit_id,
           CASE
               WHEN totals.total_amount = 0 THEN 0
               ELSE ROUND(NEW.building_amount * cei.amount / totals.total_amount, 2)
           END,
           'Distribucion proporcional al cobro total de la unidad'
    FROM common_expense_items cei
    CROSS JOIN (
        SELECT COALESCE(SUM(amount), 0) AS total_amount
        FROM common_expense_items
        WHERE common_expense_id = NEW.common_expense_id
    ) totals
    WHERE cei.common_expense_id = NEW.common_expense_id
    ON CONFLICT (concept_id, unit_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_allocate_common_expense_concept ON common_expense_concepts;
CREATE TRIGGER trg_allocate_common_expense_concept
AFTER INSERT ON common_expense_concepts
FOR EACH ROW EXECUTE FUNCTION allocate_common_expense_concept();

CREATE INDEX IF NOT EXISTS idx_concept_allocations_unit
    ON common_expense_concept_allocations(unit_id, concept_id);

