-- ============================================================
-- Migration 37: aprobacion de gastos comunes por mesa directiva
-- ============================================================
SET search_path TO lazaro, public;

ALTER TABLE common_expenses
    ADD COLUMN IF NOT EXISTS approved_by_user_id BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS approved_by_name VARCHAR(160),
    ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_common_expenses_board_approval
    ON common_expenses(condominium_id, period_yyyymm, approved_at);
