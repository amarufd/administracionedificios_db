-- ============================================================
-- Migration 10: protecciones de concurrencia para reservas, turnos y pagos
-- ============================================================
SET search_path TO lazaro, public;

CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE reservations
    DROP CONSTRAINT IF EXISTS reservations_no_overlapping_active_slots;

ALTER TABLE reservations
    ADD CONSTRAINT reservations_no_overlapping_active_slots
    EXCLUDE USING gist (
        amenity_id WITH =,
        tsrange(start_at, end_at, '[)') WITH &&
    )
    WHERE (status IN ('PENDIENTE', 'APROBADA'));

DELETE FROM shifts s
USING shifts duplicated
WHERE s.id < duplicated.id
  AND s.condominium_id = duplicated.condominium_id
  AND s.concierge_user_id = duplicated.concierge_user_id
  AND s.status = 'ACTIVO'
  AND duplicated.status = 'ACTIVO';

CREATE UNIQUE INDEX IF NOT EXISTS uq_shifts_active_concierge
    ON shifts (condominium_id, concierge_user_id)
    WHERE status = 'ACTIVO';

DELETE FROM payments p
USING payments duplicated
WHERE p.id < duplicated.id
  AND p.condominium_id = duplicated.condominium_id
  AND p.common_expense_item_id = duplicated.common_expense_item_id
  AND p.payment_method = duplicated.payment_method
  AND p.reference_number = duplicated.reference_number
  AND p.reference_number IS NOT NULL
  AND btrim(p.reference_number) <> '';

CREATE UNIQUE INDEX IF NOT EXISTS uq_payments_reference_per_item
    ON payments (condominium_id, common_expense_item_id, payment_method, reference_number)
    WHERE reference_number IS NOT NULL
      AND btrim(reference_number) <> '';
