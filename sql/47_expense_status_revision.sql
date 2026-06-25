SET search_path TO lazaro, public;

ALTER TABLE common_expenses
    ADD CONSTRAINT common_expenses_status_check
    CHECK (status IN ('EMITIDO', 'PENDIENTE_REVISION', 'PAGADO'));
