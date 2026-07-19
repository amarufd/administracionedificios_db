-- ============================================================
-- Migration 52: aprobacion de multas por mesa directiva
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE fines
    ADD COLUMN IF NOT EXISTS common_expense_id BIGINT REFERENCES common_expenses(id),
    ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP;

ALTER TABLE fines DROP CONSTRAINT IF EXISTS fines_status_check;
ALTER TABLE fines ADD CONSTRAINT fines_status_check
    CHECK (status IN ('PENDIENTE_APROBACION','EMITIDA','RECHAZADA','ANULADA','PAGADA'));

ALTER TABLE board_governance_motions
    ADD COLUMN IF NOT EXISTS target_fine_id BIGINT REFERENCES fines(id);

DROP INDEX IF EXISTS uq_board_governance_pending_type;
DROP INDEX IF EXISTS uq_board_governance_pending_target;

ALTER TABLE board_governance_motions
    DROP CONSTRAINT IF EXISTS board_governance_motions_motion_type_check;

ALTER TABLE board_governance_motions
    ADD CONSTRAINT board_governance_motions_motion_type_check
    CHECK (motion_type IN (
        'DUPLICATE_COMMON_EXPENSE',
        'REMOVE_ADMINISTRATOR',
        'SELECT_ADMINISTRATOR',
        'REMOVE_BOARD_MEMBER',
        'REPLACE_BOARD_MEMBERS',
        'APPROVE_FINE'
    ));

CREATE UNIQUE INDEX IF NOT EXISTS uq_board_governance_pending_target
    ON board_governance_motions(
        condominium_id,
        motion_type,
        COALESCE(target_admin_user_id, -1),
        COALESCE(target_board_member_user_id, -1),
        COALESCE(target_fine_id, -1)
    )
    WHERE status = 'PENDIENTE';
