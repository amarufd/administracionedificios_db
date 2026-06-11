SET search_path TO lazaro, public;

-- Ampliar CHECK constraint para incluir NO_VALIDADO
ALTER TABLE unit_short_term_rentals
  DROP CONSTRAINT unit_short_term_rentals_status_check;

ALTER TABLE unit_short_term_rentals
  ADD CONSTRAINT unit_short_term_rentals_status_check
  CHECK (status = ANY (ARRAY['NO_VALIDADO','PROGRAMADA','ACTIVA','FINALIZADA','CANCELADA']));

-- Actualizar EXCLUDE para incluir NO_VALIDADO (evita solapamiento)
ALTER TABLE unit_short_term_rentals
  DROP CONSTRAINT no_overlap_active_per_unit;

ALTER TABLE unit_short_term_rentals
  ADD CONSTRAINT no_overlap_active_per_unit
  EXCLUDE USING gist (
    unit_id WITH =,
    tsrange(start_at, end_at, '[)') WITH &&
  ) WHERE (status = ANY (ARRAY['NO_VALIDADO','ACTIVA']));

-- Nuevo default
ALTER TABLE unit_short_term_rentals
  ALTER COLUMN status SET DEFAULT 'NO_VALIDADO';

-- Migrar registros existentes PROGRAMADA → NO_VALIDADO
UPDATE unit_short_term_rentals SET status = 'NO_VALIDADO' WHERE status = 'PROGRAMADA';
