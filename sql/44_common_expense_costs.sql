-- ============================================================
-- Migration 44: desglose de costos de gastos comunes
-- ============================================================
SET search_path TO lazaro, public;

CREATE TABLE IF NOT EXISTS common_expense_costs (
    id BIGSERIAL PRIMARY KEY,
    common_expense_id BIGINT NOT NULL REFERENCES common_expenses(id) ON DELETE CASCADE,
    provider_id BIGINT NOT NULL REFERENCES providers(id),
    building_id BIGINT REFERENCES buildings(id),
    description VARCHAR(255) NOT NULL,
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    created_by_user_id BIGINT REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_common_expense_costs_expense
    ON common_expense_costs(common_expense_id);

CREATE INDEX IF NOT EXISTS idx_common_expense_costs_provider
    ON common_expense_costs(provider_id);

CREATE INDEX IF NOT EXISTS idx_common_expense_costs_building
    ON common_expense_costs(building_id) WHERE building_id IS NOT NULL;
