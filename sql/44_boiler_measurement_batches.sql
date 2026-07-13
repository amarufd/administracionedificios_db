SET search_path TO lazaro, public;

ALTER TABLE expense_measurement_imports
    ALTER COLUMN common_expense_id DROP NOT NULL,
    ADD COLUMN IF NOT EXISTS total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS base_percentage NUMERIC(5,2) NOT NULL DEFAULT 30,
    ADD COLUMN IF NOT EXISTS consumption_percentage NUMERIC(5,2) NOT NULL DEFAULT 70,
    ADD COLUMN IF NOT EXISTS total_consumption NUMERIC(18,6) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS rows_json JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE expense_measurement_imports
    DROP CONSTRAINT IF EXISTS expense_measurement_percentages_check;
ALTER TABLE expense_measurement_imports
    ADD CONSTRAINT expense_measurement_percentages_check CHECK (
        total_amount >= 0 AND total_consumption >= 0
        AND base_percentage >= 0 AND consumption_percentage >= 0
        AND base_percentage + consumption_percentage = 100
    );

CREATE INDEX IF NOT EXISTS idx_measurements_building_period
    ON expense_measurement_imports(condominium_id, building_id, period_yyyymm, uploaded_at DESC);

CREATE OR REPLACE FUNCTION validate_measurement_boiler_rules()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    boiler_enabled BOOLEAN;
    expense_period CHAR(6);
    expense_workflow VARCHAR(24);
    expense_condominium BIGINT;
    building_condominium BIGINT;
BEGIN
    SELECT has_boiler, condominium_id INTO boiler_enabled, building_condominium
      FROM buildings WHERE id = NEW.building_id;
    IF NOT COALESCE(boiler_enabled, FALSE) THEN
        RAISE EXCEPTION 'Las mediciones solo estan disponibles para edificios con caldera';
    END IF;
    IF building_condominium <> NEW.condominium_id THEN
        RAISE EXCEPTION 'La medicion y el edificio deben pertenecer al mismo condominio';
    END IF;
    IF NEW.common_expense_id IS NOT NULL THEN
        SELECT period_yyyymm, condominium_id, workflow_status
          INTO expense_period, expense_condominium, expense_workflow
          FROM common_expenses WHERE id = NEW.common_expense_id;
        IF expense_period IS NULL OR expense_period <> NEW.period_yyyymm THEN
            RAISE EXCEPTION 'El periodo del archivo de mediciones no coincide con el gasto comun';
        END IF;
        IF expense_workflow NOT IN ('BORRADOR', 'RECHAZADO') THEN
            RAISE EXCEPTION 'Las mediciones no pueden modificarse después de enviar el gasto a revisión';
        END IF;
        IF expense_condominium <> NEW.condominium_id THEN
            RAISE EXCEPTION 'La medicion y el gasto comun deben pertenecer al mismo condominio';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
