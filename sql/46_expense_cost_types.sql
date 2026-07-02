SET search_path TO lazaro, public;

ALTER TABLE common_expense_costs
    ALTER COLUMN provider_id DROP NOT NULL;

ALTER TABLE common_expense_costs
    ADD COLUMN IF NOT EXISTS cost_type VARCHAR(20) NOT NULL DEFAULT 'PROVEEDOR'
    CHECK (cost_type IN ('PROVEEDOR', 'TRABAJADOR', 'FONDO'));

ALTER TABLE common_expense_costs
    ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE common_expense_costs
    ADD COLUMN IF NOT EXISTS fund_id BIGINT REFERENCES funds(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_common_expense_costs_user
    ON common_expense_costs(user_id) WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_common_expense_costs_fund
    ON common_expense_costs(fund_id) WHERE fund_id IS NOT NULL;
